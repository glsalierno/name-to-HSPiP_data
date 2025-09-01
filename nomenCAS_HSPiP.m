% nomenCAS6_HSP.m
% 
% This script processes a list of compound names from a tab-delimited file ('chemical-data.txt'),
% retrieves CAS numbers, IUPAC names, and SMILES from PubChem using a Python helper script,
% then computes Hansen Solubility Parameters (HSP) and other properties using HSPiP software.
% 
% Requirements:
% - MATLAB (base installation sufficient)
% - Python 3.x with 'requests' library (pip install requests)
% - HSPiP software with CLI license enabled (official sources; CLI requires licensing)
% - Input file: 'chemical-data.txt' (tab-delimited, with column 'name' for compound names)
% - Python scripts: 'get_compound_info2.py' (for name-based lookup) and 'get_smiles.py' (for CAS-based SMILES; not provided here, implement similarly)
% 
% Usage:
% 1. Update 'hsip_path' to your HSPiP installation directory.
% 2. Place all files in the working directory.
% 3. Run the script.
% 
% Notes:
% - Uses caching (containers.Map) to avoid repeated API calls.
% - Includes "chemical wisdom" for typo corrections and validations (e.g., alkene/alkane checks).
% - Handles mismatches between name-based and CAS-based SMILES.
% - Outputs updated table to 'chemical-data-with-cas.txt' and .mat file with HSP results.
% - Error handling for API failures; pauses between iterations to avoid rate limiting.
% 
% Author: glsalierno
% Date: September 2025

% Define directories
current_dir = pwd;
hsip_path = 'PATH_TO_HSPIP_INSTALLATION';  % Replace with your HSPiP directory, e.g., 'C:\Path\To\HSPiP'

% Read the input file
opts = detectImportOptions('chemical-data.txt', 'Delimiter', '\t');
opts.VariableNamingRule = 'preserve';
data = readtable('chemical-data.txt', opts);

% Initialize arrays for results
cas_numbers = cell(height(data), 1);
iupac_names = cell(height(data), 1);
smiles_list = cell(height(data), 1);
hsp_results = cell(height(data), 1);

% Lookup tables for caching
compound_lookup = containers.Map();
cas_lookup = containers.Map();

% Predefine HSPiP CLI command
HSPiPcmd = ['"' fullfile(hsip_path, 'HSPiP.exe') '" Y-MBSX '];

% Chemical wisdom: Known corrections and expected CAS for common issues
known_corrections = containers.Map({'1-tetradecane'}, {'1-tetradecene'});
expected_cas = containers.Map({'1-tetradecane', '1-tetradecene'}, {'629-59-4', '1120-36-1'});

% Process each compound
for i = 1:height(data)
    compound = data.name{i};
    original_compound = compound;
    
    if isKey(known_corrections, compound)
        corrected = known_corrections(compound);
        fprintf('Chemical Wisdom: Suspected typo "%s" -> "%s" at index %d\n', compound, corrected, i);
        compound = corrected;
    end
    
    if isKey(compound_lookup, compound)
        result = compound_lookup(compound);
        cas_numbers{i} = result{1};
        iupac_names{i} = result{2};
        smiles_list{i} = result{3};
    else
        % Get name-based info first (preferred)
        [status, result] = system(['python get_compound_info2.py "' compound '"']);
        result = strtrim(result);
        parts = strsplit(result, '\t');
        
        if status == 0 && length(parts) == 3
            cas_numbers{i} = parts{1};
            iupac_names{i} = parts{2};
            smiles_list{i} = parts{3}; % Default to name-based SMILES
        else
            cas_numbers{i} = 'Not found';
            iupac_names{i} = 'Not found';
            smiles_list{i} = 'Not found';
        end
        compound_lookup(compound) = {cas_numbers{i}, iupac_names{i}, smiles_list{i}};
    end
    
    % Cross-check with CAS-based SMILES only if name-based fails
    cas = cas_numbers{i};
    name_smiles = smiles_list{i};
    if ~strcmp(cas, 'Not found') && (strcmp(name_smiles, 'Not found') || isempty(name_smiles))
        [status, cas_smiles] = system(['python get_smiles.py "' cas '" "' compound '"']);
        cas_smiles = strtrim(cas_smiles);
        if status == 0 && ~strcmp(cas_smiles, 'Not found') && ~isempty(cas_smiles)
            smiles_list{i} = cas_smiles;
            cas_lookup(cas) = cas_smiles;
            fprintf('Using CAS-based SMILES for %s (CAS %s): %s (name-based failed)\n', compound, cas, cas_smiles);
        end
    elseif ~strcmp(cas, 'Not found')
        [status, cas_smiles] = system(['python get_smiles.py "' cas '" "' compound '"']);
        cas_smiles = strtrim(cas_smiles);
        if status == 0 && ~strcmp(cas_smiles, 'Not found') && ~isempty(cas_smiles) && ~strcmp(name_smiles, cas_smiles)
            fprintf('SMILES mismatch for %s (CAS %s): %s (name) vs %s (CAS), keeping name-based\n', ...
                compound, cas, name_smiles, cas_smiles);
        end
    end
    
    % Chemical wisdom: Validate SMILES
    if ~strcmp(smiles_list{i}, 'Not found')
        if contains(compound, 'ene') && ~contains(compound, 'benzene') && ~contains(smiles_list{i}, '=')
            fprintf('Chemical Wisdom Warning: "%s" (alkene) has SMILES "%s" without double bond at index %d\n', ...
                compound, smiles_list{i}, i);
        elseif contains(compound, 'ane') && ~contains(compound, 'di') && ~contains(compound, 'cyclo') && contains(smiles_list{i}, '=')
            fprintf('Chemical Wisdom Warning: "%s" (alkane) has SMILES "%s" with double bond at index %d\n', ...
                compound, smiles_list{i}, i);
        elseif contains(lower(compound), 'nitrile') && ~contains(smiles_list{i}, '#N')
            fprintf('Chemical Wisdom Warning: "%s" (nitrile) has SMILES "%s" without triple bond at index %d\n', ...
                compound, smiles_list{i}, i);
        end
    elseif isKey(expected_cas, compound)
        suggested_cas = expected_cas(compound);
        fprintf('Chemical Wisdom: No SMILES for "%s", trying expected CAS %s\n', compound, suggested_cas);
        [status, cas_smiles] = system(['python get_smiles.py "' suggested_cas '" "' compound '"']);
        cas_smiles = strtrim(cas_smiles);
        if status == 0 && ~strcmp(cas_smiles, 'Not found') && ~isempty(cas_smiles)
            cas_numbers{i} = suggested_cas;
            smiles_list{i} = cas_smiles;
            iupac_names{i} = compound;
        end
    end
    
    % Run HSPiP if SMILES is valid
    if ~strcmp(smiles_list{i}, 'Not found')
        cd(hsip_path);
        system([HSPiPcmd '"' smiles_list{i} '"']);
        hsp_opts = detectImportOptions('Out.dat', 'Delimiter', '\t');
        hsp_opts.VariableNamingRule = 'preserve';
        hsp_results{i} = readtable('Out.dat', hsp_opts);
        cd(current_dir);
    else
        hsp_results{i} = [];
    end
    
    fprintf('%d/%d: %s -> CAS: %s, IUPAC: %s, SMILES: %s\n', ...
        i, height(data), original_compound, cas_numbers{i}, iupac_names{i}, smiles_list{i});
    pause(0.2);  % Pause to avoid API rate limiting
end

% Duplicate CAS check
cas_list = cas_numbers;
unique_cas = unique(cas_list(~strcmp(cas_list, 'Not found')));
for cas = unique_cas'
    indices = find(strcmp(cas_list, cas{1}));
    if length(indices) > 1
        smiles_set = smiles_list(indices);
        iupac_set = iupac_names(indices);
        if length(unique(smiles_set(~strcmp(smiles_set, 'Not found')))) > 1 || ...
           length(unique(iupac_set(~strcmp(iupac_set, 'Not found')))) > 1
            fprintf('Warning: CAS %s has multiple SMILES/IUPAC:\n', cas{1});
            for idx = indices'
                fprintf('  %s -> SMILES: %s, IUPAC: %s at index %d\n', ...
                    data.name{idx}, smiles_list{idx}, iupac_names{idx}, idx);
            end
        end
    end
end

% Add columns to table
data.CAS = cas_numbers;
data.IUPAC = iupac_names;
data.SMILES = smiles_list;

% Save results
writetable(data, 'chemical-data-with-cas.txt', 'Delimiter', '\t');
save('CAS_SMILES_HSP.mat', 'data', 'hsp_results', '-v7.3');