"""GENERATED - do not edit. Template: service.py.tpl"""

SERVICE_NAME = "%{NAME}"
SERVICE_PORT = %{PORT}
ENDPOINTS = %{ENDPOINTS}


def describe():
    return f"{SERVICE_NAME} on :{SERVICE_PORT} serving {len(ENDPOINTS)} endpoints"


if __name__ == "__main__":
    print(describe())
    for endpoint in ENDPOINTS:
        print("  -", endpoint)
