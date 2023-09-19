
from __future__ import absolute_import, division, print_function

__metaclass__ = type

from ansible.errors import AnsibleFilterError
import json


class FilterModule(object):

    def filters(self):
        return {
            "nexus_groovy_error": self.nexus_groovy_error,
            "nexus_groovy_changed": self.nexus_groovy_changed,
            "nexus_groovy_details": self.nexus_groovy_details,
        }

    def nexus_groovy_error(self, data):

        return self._nexus_groovy_result(data, "error")

    def nexus_groovy_changed(self, data):

        return self._nexus_groovy_result(data, "changed")

    def nexus_groovy_details(self, data):

        return self._nexus_groovy_result(data, "action_details")

    def _nexus_groovy_result(self, data, element):

        valid_elements = ["error", "changed", "action_details"]
        if element not in valid_elements:
            raise AnsibleFilterError(
                f"The element parameter must be one of {','.join(valid_elements)}"
            )

        return self._get_script_run_results(data)[element]

    def _get_script_run_results(self, data):

        try:
            request_status = data["status"]
        except KeyError:
            raise AnsibleFilterError(
                "The input data is not valid. It does not contain the key 'status'. "
                "Is it a var registered from a uri: module call ?"
            )

        try:
            json_data = data["json"]
        except KeyError:
            raise AnsibleFilterError(
                "The input data is not valid. It does not contain the key 'json'. "
                "Is it a var registered from a uri: module call ?"
            )

        try:
            raw_result = json_data["result"]
            if raw_result == "null":
                raise KeyError
        except KeyError:
            raw_result = None

        try:
            result = json.loads(raw_result)
            if result is None:
                raise ValueError
        except (ValueError, TypeError):
            if request_status == 200:
                result = {
                    "error": False,
                    "changed": False,
                    "action_details": raw_result
                    if raw_result
                    else "Script return in empty",
                }
            else:
                result = {
                    "error": True,
                    "changed": False,
                    "action_details": raw_result
                    if raw_result
                    else "Global script failure",
                }
        except Exception as e:
            raise AnsibleFilterError(
                f"Filter encountered an unexpected exception: {type(e)} {e}"
            )

        return result
