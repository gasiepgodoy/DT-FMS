#!/usr/bin/env python3
"""
Script de chargement automatique des AAS Polimi dans NOVAAS
Usage : /opt/homebrew/bin/python3.11 load_polimi_aas.py
"""
import urllib.request, urllib.error, json, base64, time

BASE = "http://localhost:1872"
AUTH = base64.b64encode(b"admin:password").decode()
HEADERS = {"Content-Type": "application/json", "Authorization": f"Basic {AUTH}"}

def api(method, path, data=None):
    req = urllib.request.Request(
        f"{BASE}{path}",
        data=json.dumps(data).encode() if data else None,
        headers=HEADERS,
        method=method
    )
    try:
        with urllib.request.urlopen(req) as r:
            resp = r.read()
            return json.loads(resp) if resp else {}
    except urllib.error.HTTPError as e:
        return {"error": e.read().decode()}

def b64(s):
    return base64.b64encode(s.encode()).decode()

STATIONS = {
    1: {"A": (True, "Drop 1 Cover"), "B": (True, "Drop 1 Cover"), "C": (True, "Drop 1 Cover")},
    2: {"A": (True, "2 Holes"),      "B": (True, "4 Holes"),      "C": (True, "2 Holes")},
    3: {"A": (False, None),          "B": (True, None),           "C": (False, None)},
    4: {"A": (False, None),          "B": (True, "2 Picture"),    "C": (True, "1 Picture")},
    5: {"A": (True, "Drop 1 Cover"), "B": (True, "Drop 1 Cover"), "C": (False, None)},
    6: {"A": (True, "Pressing"),     "B": (True, "Pressing"),     "C": (False, None)},
    7: {"A": (True, "Manual Pickup"),"B": (True, "Robot Pickup"), "C": (True, "Manual Pickup")},
}

def create_station(i):
    aas_id = f"urn:polimi:dtfms:aas:station{i}"
    aas_id_b64 = b64(aas_id)

    # Supprimer si déjà existant
    api("DELETE", f"/shells/{aas_id_b64}")
    time.sleep(0.3)

    # Créer AAS
    r = api("POST", "/shells", {
        "idShort": f"Station{i}_Polimi",
        "id": aas_id,
        "assetInformation": {"assetKind": "Instance", "globalAssetId": f"urn:polimi:dtfms:asset:station{i}"},
        "submodels": []
    })
    if "error" in r:
        print(f"  ❌ AAS erreur: {r}")
        return
    time.sleep(0.3)

    # OperationalData
    r = api("POST", f"/shells/{aas_id_b64}/submodels", {
        "idShort": "OperationalData",
        "id": f"urn:polimi:dtfms:submodel:station{i}:operational",
        "submodelElements": [
            {"modelType": "SubmodelElementCollection", "idShort": "Sensors", "value": [
                {"modelType": "Property", "idShort": "CartPresent", "valueType": "xs:boolean", "value": "false"},
                {"modelType": "Property", "idShort": "OperationDone", "valueType": "xs:boolean", "value": "false"}
            ]},
            {"modelType": "SubmodelElementCollection", "idShort": "Actuators", "value": [
                {"modelType": "Property", "idShort": "Action", "valueType": "xs:boolean", "value": "false"},
                {"modelType": "Property", "idShort": "Bypass", "valueType": "xs:boolean", "value": "false"},
                {"modelType": "Property", "idShort": "Release", "valueType": "xs:boolean", "value": "false"}
            ]},
            {"modelType": "SubmodelElementCollection", "idShort": "Status", "value": [
                {"modelType": "Property", "idShort": "StationState", "valueType": "xs:string", "value": "IDLE"},
                {"modelType": "Property", "idShort": "CurrentProduct", "valueType": "xs:string", "value": ""}
            ]}
        ]
    })
    time.sleep(0.3)

    # ProductRouting
    routing_elements = []
    for prod, (stop, op) in STATIONS[i].items():
        routing_elements.append({"modelType": "Property", "idShort": f"Product{prod}_Stop", "valueType": "xs:boolean", "value": str(stop).lower()})
        routing_elements.append({"modelType": "Property", "idShort": f"Product{prod}_Op", "valueType": "xs:string", "value": op or "Bypass"})

    api("POST", f"/shells/{aas_id_b64}/submodels", {
        "idShort": "ProductRouting",
        "id": f"urn:polimi:dtfms:submodel:station{i}:routing",
        "submodelElements": routing_elements
    })
    time.sleep(0.3)
    print(f"  ✅ Station{i}_Polimi chargée")

print("Chargement des AAS Polimi dans NOVAAS...")
for i in range(1, 8):
    print(f"Station {i}...")
    create_station(i)

print("\n✅ Toutes les stations chargées !")
shells = api("GET", "/shells")
print(f"Total AAS dans NOVAAS : {len(shells)}")
for s in shells:
    print(f"  - {s.get('idShort')}")
