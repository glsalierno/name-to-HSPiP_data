# name-to-HSPiP_data
Scripts to retrieve CAS numbers, IUPAC names, and SMILES from compound names via PubChem API, then compute Hansen Solubility Parameters (HSP) using HSPiP. Features chemical validation. MATLAB-Python integration.

# Compound Name to CAS, SMILES, and HSP Retrieval

This repository contains scripts to process compound names, fetch CAS, IUPAC, and SMILES from PubChem, and compute HSP using HSPiP software. Includes validation for chemical consistency.

## Files
- `nomenCAS6_HSP.m`: MATLAB script for processing names, integrating with Python, and HSPiP.
- `get_compound_info2.py`: Python script for name-based PubChem lookups.
- Note: `get_smiles.py` (CAS-based SMILES) is referenced but not included; implement using similar API calls if needed.

## Requirements
- **Python 3.x**: With `requests` library (`pip install requests`).
- **MATLAB**: Base installation; no additional toolboxes needed.
- **HSPiP Software**: Installed with CLI license enabled (from official providers; CLI requires licensing).
- Input file: 'chemical-data.txt' (tab-delimited with 'name' column).

## Usage
1. Place files in the working directory.
2. Update paths in MATLAB script.
3. Prepare input file with compound names.
4. Run the MATLAB script.

## Notes
- Complies with PubChem API terms and HSPiP licensing.
- Includes "chemical wisdom" for corrections and warnings.
- For issues, open a GitHub issue.

Author: glsalierno  
Date: September 2025  
GitHub: [glsalierno](https://github.com/glsalierno)
