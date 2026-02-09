from slpp import slpp as lua
import os
import re
import json


# Read the lua file
def read_lua_file(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        data = f.read()
        # Replace color codes "|cff808080" with regex
        removeColor = re.compile(r"\|c[a-fA-F0-9]{8}")
        removeColorEnd = re.compile(r"\|r")
        data = removeColor.sub("", data)
        data = removeColorEnd.sub("", data)

        return data


py_data = lua.decode(read_lua_file(os.path.join(os.path.dirname(__file__), "data.lua")))


print(json.dumps(py_data, indent=4))
