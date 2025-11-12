"""Report generation module for units extraction results."""

import os
from datetime import datetime
from typing import List, Dict, Any


def generate_units_report(extraction_result: List[Dict[str, Any]], output_dir: str, cutout_manifest_path: str = None) -> str:
    """
    Generate a comprehensive markdown report containing all units information and installment plans.
    
    Args:
        extraction_result: List of unit data from extraction
        output_dir: Output directory path
        cutout_manifest_path: Path to cutout manifest file (optional)
    
    Returns:
        Path to the generated markdown report file
    """
    report_path = os.path.join(output_dir, "report.md")
    
    # Load cutout manifest if provided
    cutout_manifest = {}
    if cutout_manifest_path and os.path.exists(cutout_manifest_path):
        import json
        with open(cutout_manifest_path, 'r', encoding='utf-8') as f:
            cutout_manifest = json.load(f)
    
    with open(report_path, 'w', encoding='utf-8') as f:
        # Header
        f.write("# Contract Information Extraction Report\n\n")
        f.write(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | **Units:** {len(extraction_result)}\n\n")
        
        # Table of Contents
        f.write("## Table of Contents\n\n")
        f.write("- [Units Information](#units-information)\n")
        f.write("- [Installment Plans](#installment-plans)\n")
        f.write("- [Summary](#summary)\n\n")
        
        # Units Information Section
        f.write("## Units Information\n\n")
        
        # Process each unit
        for unit_idx, unit_data in enumerate(extraction_result):
            unit = unit_data.get('unit', unit_data)
            confidence = unit_data.get('confidence', {})
            
            f.write(f"### Unit {unit_idx + 1}\n\n")
            
            # Get cutout images for this unit
            unit_cutouts = {}
            for field_key, cutout_paths in cutout_manifest.items():
                if f"unit{unit_idx + 1}_" in field_key:
                    field_name = field_key.replace(f"unit{unit_idx + 1}_", "")
                    unit_cutouts[field_name] = cutout_paths
            
            # Define field order and labels
            field_info = [
                ("unitCode", "Unit Code"),
                ("areaM2", "Area (m²)"),
                ("sellValue", "Sell Value (R$)"),
                ("pricePerM2", "Price per m² (R$)"),
                ("buyerName", "Buyer Name"),
                ("signingDate", "Signing Date"),
            ]
            
            # Create table for each field
            for field_key, field_label in field_info:
                value = unit.get(field_key, 'N/A')
                conf = confidence.get(field_key, 'unknown')
                conf_emoji = {"high": "🟢", "medium": "🟡", "low": "🔴"}.get(conf, "⚪")
                
                # Format values based on field type
                formatted_value = _format_field_value(field_key, value)
                
                f.write(f"### {field_label}\n\n")
                
                f.write("| | |\n")
                f.write("|---|---|\n")
                f.write(f"| **Name** | {field_label} |\n")
                f.write(f"| **Value** | {formatted_value} |\n")
                f.write(f"| **Confidence** | {conf_emoji} {conf} |\n")
                
                # Add image row if cutout exists
                if field_key in unit_cutouts and unit_cutouts[field_key]:
                    relative_path = os.path.relpath(unit_cutouts[field_key][0], output_dir)
                    f.write(f"| **Image** | ![{field_label}]({relative_path}) |\n")
                else:
                    f.write(f"| **Image** | *No image available* |\n")
                
                f.write("\n")
            
            f.write("---\n\n")
        
        # Installment Plans Section
        f.write("## Installment Plans\n\n")
        
        # Process installment plans for each unit
        for unit_idx, unit_data in enumerate(extraction_result):
            unit = unit_data.get('unit', unit_data)
            installment_plans = unit.get('installmentPlans', [])
            
            if installment_plans:
                f.write(f"### Unit {unit_idx + 1} - {unit.get('unitCode', 'Unknown Unit')}\n\n")
                
                for plan_idx, plan in enumerate(installment_plans):
                    f.write(f"#### Plan {plan_idx + 1}\n\n")
                    
                    # Create table for installment plan details
                    f.write("| Field | Value |\n")
                    f.write("|-------|-------|\n")
                    f.write(f"| **Series** | {plan.get('series', 'N/A')} |\n")
                    f.write(f"| **Total Installments** | {plan.get('totalInstallments', 'N/A')} |\n")
                    f.write(f"| **Installment Amount** | {_format_currency(plan.get('installmentAmount', 'N/A'))} |\n")
                    f.write(f"| **Total Value** | {_format_currency(plan.get('totalValue', 'N/A'))} |\n")
                    f.write(f"| **First Due Date** | {plan.get('firstDueDate', 'N/A')} |\n")
                    f.write(f"| **Indexer Code** | {plan.get('indexerCode', 'N/A')} |\n")
                    f.write(f"| **Confidence** | {plan.get('confidence', 'N/A')} |\n")
                    
                    # Add cutout images for installment plans
                    installment_cutouts = []
                    for field_key, cutout_paths in cutout_manifest.items():
                        if f"unit{unit_idx + 1}_installmentPlans" in field_key:
                            installment_cutouts.extend(cutout_paths)
                    
                    if installment_cutouts:
                        f.write(f"\n**Source Images:**\n\n")
                        for cutout_path in installment_cutouts:
                            relative_path = os.path.relpath(cutout_path, output_dir)
                            f.write(f"![Installment Plan Source]({relative_path})\n\n")
                    else:
                        f.write(f"\n*No source images available*\n\n")
                    
                    f.write("---\n\n")
            else:
                f.write(f"### Unit {unit_idx + 1} - {unit.get('unitCode', 'Unknown Unit')}\n\n")
                f.write("*No installment plans found - Unit may be paid (QUITADA)*\n\n")
        
        # Summary statistics
        f.write("## Summary\n\n")
        
        # Calculate totals
        total_value = 0
        total_area = 0
        valid_units = 0
        total_installment_plans = 0
        
        for unit_data in extraction_result:
            unit = unit_data.get('unit', unit_data)
            installment_plans = unit.get('installmentPlans', [])
            total_installment_plans += len(installment_plans)
            
            try:
                if unit.get('sellValue'):
                    total_value += float(unit.get('sellValue', 0))
                if unit.get('areaM2'):
                    total_area += float(unit.get('areaM2', 0))
                valid_units += 1
            except (ValueError, TypeError):
                continue
        
        f.write(f"**Total Value:** R$ {total_value:,.2f} | ")
        f.write(f"**Total Area:** {total_area:,.2f} m² | ")
        if total_area > 0:
            f.write(f"**Avg Price/m²:** R$ {total_value/total_area:.2f} | ")
        f.write(f"**Total Installment Plans:** {total_installment_plans}\n\n")
        
        # Confidence summary (simplified)
        all_confidences = {}
        for unit_data in extraction_result:
            confidence = unit_data.get('confidence', {})
            for field, conf in confidence.items():
                if field not in all_confidences:
                    all_confidences[field] = []
                all_confidences[field].append(conf)
        
        low_conf_count = sum(1 for confs in all_confidences.values() for conf in confs if conf == 'low')
        if low_conf_count > 0:
            f.write(f"⚠️ **{low_conf_count} fields with low confidence**\n\n")
        
        f.write("*Report complete*\n")
    
    return report_path


def _format_field_value(field_key: str, value) -> str:
    """
    Format field values based on their type.
    
    Args:
        field_key: The field key
        value: The value to format
        
    Returns:
        Formatted string value
    """
    if value is None or value == 'N/A':
        return 'N/A'
    
    # Format currency fields
    if field_key in ['sellValue', 'pricePerM2']:
        try:
            num_value = float(value)
            return f"R$ {num_value:,.2f}"
        except (ValueError, TypeError):
            return str(value)
    
    # Format area fields
    elif field_key == 'areaM2':
        try:
            num_value = float(value)
            return f"{num_value:,.2f} m²"
        except (ValueError, TypeError):
            return str(value)
    
    # Format dates
    elif field_key == 'signingDate':
        if value and value != 'N/A':
            return str(value)
        return 'N/A'
    
    
    # Default formatting
    return str(value)


def _format_currency(value) -> str:
    """
    Format currency values.
    
    Args:
        value: The value to format
        
    Returns:
        Formatted currency string
    """
    if value is None or value == 'N/A':
        return 'N/A'
    
    try:
        num_value = float(value)
        return f"R$ {num_value:,.2f}"
    except (ValueError, TypeError):
        return str(value)