# get_compound_info2.py
#
# This script fetches CAS number, IUPAC name, and Isomeric SMILES from PubChem for a given compound name.
# It uses the PubChem PUG REST API.
#
# Requirements:
# - Python 3.x
# - requests library (install via: pip install requests)
# - logging library (built-in)
#
# Usage:
# python get_compound_info2.py <compound_name>
#
# Example:
# python get_compound_info2.py ethanol
#
# Output:
# Tab-delimited string: CAS\tIUPAC\tSMILES
# If not found or error: "Not found\tNot found\tNot found"
#
# Notes:
# - Logs errors to console.
# - Uses first CID found; assumes primary match.
# - CAS extracted from synonyms (numeric with dashes).
# - Timeout set to 10 seconds for requests.
#
# Author: glsalierno
# Date: September 2025

import sys
import requests
import logging
from urllib.parse import quote
from pubchem_http import pubchem_get

LOG = logging.getLogger(__name__)
TIMEOUT = 10
NOT_FOUND = "Not found\tNot found\tNot found"

def get_compound_info(compound_name):
    base_url = 'https://pubchem.ncbi.nlm.nih.gov/rest/pug'
    try:
        # Get CID by name
        cid_url = f"{base_url}/compound/name/{quote(compound_name, safe='')}/cids/JSON"
        response = pubchem_get(cid_url, timeout=TIMEOUT, context=f"{compound_name}: CID lookup")
        data = response.json()
        cid = data['IdentifierList']['CID'][0]
        
        # Get CAS from synonyms
        synonyms_url = f'{base_url}/compound/cid/{cid}/synonyms/JSON'
        response = pubchem_get(synonyms_url, timeout=TIMEOUT, context=f"{compound_name}: synonyms")
        synonyms = response.json()['InformationList']['Information'][0]['Synonym']
        cas = next((s for s in synonyms if s.replace('-', '').isdigit()), 'Not found')
        
        # Get IUPAC
        iupac_url = f'{base_url}/compound/cid/{cid}/property/IUPACName/TXT'
        iupac = pubchem_get(iupac_url, timeout=TIMEOUT, context=f"{compound_name}: IUPAC name").text.strip()
        
        # Get SMILES
        smiles_url = f'{base_url}/compound/cid/{cid}/property/SMILES/TXT'
        smiles = pubchem_get(smiles_url, timeout=TIMEOUT, context=f"{compound_name}: SMILES").text.strip()
        
        return f"{cas}\t{iupac}\t{smiles}"
    except requests.exceptions.JSONDecodeError as e:
        LOG.error("%s: invalid PubChem JSON: %s", compound_name, e)
    except requests.RequestException as e:
        LOG.error("%s: PubChem request failed: %s", compound_name, e)
    except (ValueError, KeyError, IndexError, TypeError, AttributeError) as e:
        LOG.error("%s: unexpected PubChem response: %s", compound_name, e)
    return NOT_FOUND

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    if len(sys.argv) < 2:
        print("Usage: python get_compound_info2.py <compound_name>")
        sys.exit(1)
    print(get_compound_info(sys.argv[1]))
