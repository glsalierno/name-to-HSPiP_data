[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/glsalierno/pubchem-toxinfo-cas-retriever/blob/main/LICENSE)
[![Python 3.x](https://img.shields.io/badge/python-3.x-blue.svg)](https://www.python.org/downloads/)
[![MATLAB](https://img.shields.io/badge/MATLAB-R2014b%2B-orange.svg)](https://www.mathworks.com/products/matlab.html)
# Name to CAS, SMILES, and HSP Retrieval

This repository provides scripts to retrieve CAS numbers, IUPAC names, and SMILES from compound names via the PubChem API, then compute Hansen Solubility Parameters (HSP) using the HSPiP software. It includes chemical validation ("chemical wisdom") for corrections and warnings, with MATLAB-Python integration.

## About the Repository
- **Purpose**: Automate conversion of compound names to chemical identifiers (via PubChem) and HSP values (via HSPiP CLI).
- **Key Features**: API lookups, SMILES validation, retries for mismatches, and "chemical wisdom" for common errors (e.g., alkene/alkane checks).
- **DOI**: [10.5281/zenodo.18475390](https://doi.org/10.5281/zenodo.18475390)  <!-- Update if different -->
- **Author**: glsalierno (GitHub: [glsalierno](https://github.com/glsalierno))
- **Date**: February 2026  <!-- Updated to current; adjust as needed -->
- **License**: MIT (see [LICENSE](LICENSE))

## Files
- `nomenCAS_HSPiP.m`: MATLAB script to process names, call Python for PubChem data, apply validations, and integrate with HSPiP.
- `get_compound_info2.py`: Python script to fetch CAS, IUPAC, and SMILES from PubChem using compound names.
- `README.md`: This file.
- `LICENSE`: MIT license.

**Note**: The script references `get_smiles.py` for CAS-based SMILES cross-checks, but it's not included. See "Missing Scripts" below for a sample implementation.

## Requirements
### Must-Haves
- **Python 3.x**: Install via [python.org](https://www.python.org/).
  - Required packages: `requests` (`pip install requests`).
- **MATLAB**: Base installation (no extra toolboxes needed). Tested on recent versions.
- **HSPiP Software**: Must be installed with CLI mode enabled. Obtain from the official HSPiP website: [HSPiP | Hansen Solubility Parameters](https://www.hansen-solubility.com/HSPiP). CLI requires a specific license—contact HSPiP support if unsure. For details on the Command Line Interface, see [HSPiP CLI Documentation](https://www.hansen-solubility.com/HSPiP/CLI.php) and the associated guide: [HSPiP Command Line Interface.docx](https://www.hansen-solubility.com/contents/HSPiP%20Command%20Line%20Interface.docx). Update script paths to point to your local HSPiP installation directory.

### Optional
- `get_smiles.py`: For CAS-based fallbacks (implement as shown below).

**Note**: Internet access required for PubChem queries (no internet for HSPiP). Ensure compliance with [PubChem API terms](https://pubchem.ncbi.nlm.nih.gov/docs/programmatic-access) (e.g., rate limits: ~5 requests/second; script includes pauses).

---

> **⚠️ IMPORTANT: Update Paths Before Running**
>
> You **must** edit `nomenCAS_HSPiP.m`:
>
> - Search for `hsip_path = 'PATH_TO_HSPIP_INSTALLATION';` (near line 27, in "Define directories" section).  
>   Example: `'C:\\Program Files\\Hansen-Solubility\\HSPiP'`
>
> Replace the placeholder with your actual path (use single backslashes or forward slashes; MATLAB handles both).

## Quick Start Guide
1. Clone this repository: `git clone https://github.com/glsalierno/name-to-HSPiP_data.git`.
2. Place all files in the same directory. Implement `get_smiles.py` if needed (see below).
3. Prepare input: Create `chemical-data.txt` (tab-delimited) with a `name` column. Example:
   
    name
    ethanol
    formaldehyde

4. **Update the paths as shown in the ⚠️ IMPORTANT box above.**
5. Run in MATLAB: Open and execute `nomenCAS_HSPiP.m`. It will:
- Load names from `chemical-data.txt`.
- Call `get_compound_info2.py` for PubChem data (name-based).
- Optionally call `get_smiles.py` for CAS-based cross-checks.
- Apply "chemical wisdom" validations.
- Run HSPiP CLI for HSP computation.
6. Output: Updated table in `chemical-data-with-cas.txt` (with CAS, IUPAC, SMILES). HSP results in `CAS_SMILES_HSP.mat` (MATLAB file with tables).

## Detailed Usage Notes
- **Customizing Scripts**: Edit pauses (e.g., `pause(0.2)`) for rate limits or add more "chemical wisdom" rules in the MATLAB script.
- **Example Output**: For "ethanol", expect CAS '64-17-5', IUPAC 'ethanol', SMILES 'CCO', HSP values like δD=15.8, δP=8.8, δH=19.4 (approximate; depends on HSPiP version).
- **Integration Details**: MATLAB uses `system()` to call Python scripts—ensure Python is in your system PATH. HSPiP runs via CLI with `HSPiP.exe Y-MBSX "SMILES"`.
- **Chemical Wisdom**: Built-in checks for typos (e.g., "1-tetradecane" → "1-tetradecene") and validations (e.g., warn if alkene SMILES lacks '='). Console logs warnings.

## Troubleshooting

PubChem Errors: Check API status; increase pauses if hitting rate limits.
HSPiP Fails: Verify CLI license and paths. Test HSPiP CLI manually (e.g., HSPiP.exe Y-MBSX "CCO").
SMILES Mismatches: Script logs warnings; manually verify with PubChem.
Missing get_smiles.py: Implement as above or disable CAS cross-checks in MATLAB.
MATLAB-Python Bridge Fails: Confirm Python path in MATLAB (use pyenv).
If stuck, open an issue with error logs.

## References

- Official HSPiP Website: [HSPiP | Hansen Solubility Parameters](https://www.hansen-solubility.com/HSPiP)
- HSPiP CLI Documentation: [Command Line Interface (CLI)](https://www.hansen-solubility.com/HSPiP/CLI.php)
- HSPiP CLI Guide: [HSPiP Command Line Interface.docx](https://www.hansen-solubility.com/contents/HSPiP%20Command%20Line%20Interface.docx)
- PubChem API: [Programmatic Access Documentation](https://pubchem.ncbi.nlm.nih.gov/docs/programmatic-access)

