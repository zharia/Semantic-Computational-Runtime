#!/usr/bin/env python3
"""
SCR MaterialX Shading Closure Provider & Document Generator
Compiles 96 optical appearance contracts from materials_catalog.json into MaterialX v1.38 XML documents.
"""

import json
import os
import xml.etree.ElementTree as ET
from xml.dom import minidom

SCR_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
CATALOG_PATH = os.path.join(SCR_ROOT, "lib/A01_Render/Material/materials_catalog.json")
OUTPUT_MTLX_PATH = os.path.join(SCR_ROOT, "lib/A01_Render/Material/providers/unified_materials.mtlx")

def generate_materialx():
    with open(CATALOG_PATH, "r") as f:
        catalog = json.load(f)

    materials = catalog.get("materials", [])

    # Root MaterialX node
    root = ET.Element("materialx", version="1.38", xmlns="http://www.materialx.org/XML/v1")
    root.append(ET.Comment(f" SCR Universal Materials Catalog MaterialX Export ({len(materials)} Materials) "))

    for mat in materials:
        raw_id = mat["id"]
        safe_id = raw_id.replace(".", "_")
        name = mat.get("name", safe_id)
        opt = mat.get("optical", {})

        albedo = opt.get("base_color_srgb", [0.5, 0.5, 0.5])
        roughness = opt.get("roughness", 0.5)
        metallic = opt.get("metallic", 0.0)
        ior = opt.get("ior", 1.5)
        trans = opt.get("transmission", 0.0)
        emiss = opt.get("emission_cd_m2", 0.0)

        # Standard Surface Shader Node
        shader_name = f"SR_{safe_id}"
        shader = ET.SubElement(root, "standard_surface", name=shader_name, type="surfaceshader")
        
        # Base Color
        ET.SubElement(shader, "input", name="base", type="float", value="1.0")
        ET.SubElement(shader, "input", name="base_color", type="color3", value=f"{albedo[0]:.4f}, {albedo[1]:.4f}, {albedo[2]:.4f}")
        
        # Specular & Roughness
        ET.SubElement(shader, "input", name="specular", type="float", value="1.0")
        ET.SubElement(shader, "input", name="specular_roughness", type="float", value=f"{roughness:.4f}")
        ET.SubElement(shader, "input", name="specular_IOR", type="float", value=f"{ior:.4f}")
        
        # Metallic
        ET.SubElement(shader, "input", name="metalness", type="float", value=f"{metallic:.4f}")
        
        # Transmission
        if trans > 0.0:
            ET.SubElement(shader, "input", name="transmission", type="float", value=f"{trans:.4f}")
            ET.SubElement(shader, "input", name="transmission_color", type="color3", value=f"{albedo[0]:.4f}, {albedo[1]:.4f}, {albedo[2]:.4f}")
        
        # Emission
        if emiss > 0.0:
            # Normalize emission weight for standard surface
            emiss_weight = min(1.0, emiss / 1000.0)
            ET.SubElement(shader, "input", name="emission", type="float", value=f"{emiss_weight:.4f}")
            ET.SubElement(shader, "input", name="emission_color", type="color3", value=f"{albedo[0]:.4f}, {albedo[1]:.4f}, {albedo[2]:.4f}")

        # Surfacematerial Node Binding
        mat_node_name = f"M_{safe_id}"
        mat_node = ET.SubElement(root, "surfacematerial", name=mat_node_name, type="material")
        ET.SubElement(mat_node, "input", name="surfaceshader", type="surfaceshader", nodename=shader_name)

    # Format XML nicely
    xml_str = ET.tostring(root, encoding="utf-8")
    parsed = minidom.parseString(xml_str)
    pretty_xml = parsed.toprettyxml(indent="  ")

    with open(OUTPUT_MTLX_PATH, "w") as f:
        f.write(pretty_xml)

    # Validate output XML
    ET.parse(OUTPUT_MTLX_PATH)
    print(f"Successfully compiled {len(materials)} materials into MaterialX document: {OUTPUT_MTLX_PATH}")
    return len(materials)

if __name__ == "__main__":
    generate_materialx()
