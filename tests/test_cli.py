import unittest
from unittest.mock import Mock, patch

import requests

import get_compound_info2 as lookup


class LookupTests(unittest.TestCase):
    def test_preserves_tab_delimited_protocol_and_timeout(self):
        replies = [
            Mock(json=lambda: {"IdentifierList": {"CID": [702]}}),
            Mock(json=lambda: {"InformationList": {"Information": [{"Synonym": ["ethanol", "64-17-5"]}]}}),
            Mock(text="ethanol\n"),
            Mock(text="CCO\n"),
        ]
        with patch.object(lookup, "pubchem_get", side_effect=replies) as get:
            result = lookup.get_compound_info("ethyl alcohol")
        self.assertEqual(result, "64-17-5\tethanol\tCCO")
        self.assertIn("ethyl%20alcohol", get.call_args_list[0].args[0])
        self.assertTrue(all(call.kwargs["timeout"] == 10 for call in get.call_args_list))

    def test_failed_property_does_not_enter_data_stream(self):
        with patch.object(lookup, "pubchem_get", side_effect=requests.Timeout), self.assertLogs(level="ERROR"):
            self.assertEqual(lookup.get_compound_info("ethanol"), lookup.NOT_FOUND)
