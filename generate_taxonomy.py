
import re
import csv
import sys

def parse_taxonomy(html_path, csv_path):
    with open(html_path, 'r') as f:
        content = f.read()

    # Map prefixes to Main Category Names
    prefix_map = {
        'cs': 'Computer Science',
        'econ': 'Economics',
        'eess': 'Electrical Engineering and Systems Science',
        'math': 'Mathematics',
        'astro-ph': 'Astrophysics',
        'cond-mat': 'Condensed Matter',
        'gr-qc': 'General Relativity and Quantum Cosmology',
        'hep-ex': 'High Energy Physics - Experiment',
        'hep-lat': 'High Energy Physics - Lattice',
        'hep-ph': 'High Energy Physics - Phenomenology',
        'hep-th': 'High Energy Physics - Theory',
        'math-ph': 'Mathematical Physics',
        'nlin': 'Nonlinear Sciences',
        'nucl-ex': 'Nuclear Experiment',
        'nucl-th': 'Nuclear Theory',
        'physics': 'Physics',
        'quant-ph': 'Quantum Physics',
        'q-bio': 'Quantitative Biology',
        'q-fin': 'Quantitative Finance',
        'stat': 'Statistics'
    }

    categories = []

    # Regex to find codes and names
    # Matches <h4>cs.AI <span>(Artificial Intelligence)</span></h4>
    pattern = re.compile(r'<h4>([a-zA-Z0-9.-]+)\s*<span>\((.*?)\)</span></h4>')
    
    for match in pattern.finditer(content):
        code = match.group(1)
        name = match.group(2)
        
        if '.' in code:
            prefix = code.split('.')[0]
        else:
            prefix = code

        # Handle mapped main category name
        main_category_name = prefix_map.get(prefix, prefix.upper())
        
        # We will output: MainCategoryName, MainCategoryID, SubCategoryName, SubCategoryID, SubCategoryCode
        categories.append({
            'main_id': prefix,
            'main_name': main_category_name,
            'sub_id': code,
            'sub_name': name,
            'sub_code': code
        })

    # Sort
    categories.sort(key=lambda x: (x['main_name'], x['sub_code']))

    # Write CSV
    with open(csv_path, 'w', newline='') as csvfile:
        fieldnames = ['main_id', 'main_name', 'sub_id', 'sub_name', 'sub_code']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        for cat in categories:
            writer.writerow(cat)
            
if __name__ == "__main__":
    parse_taxonomy("/Users/deringezgin/Projects/PaperScope/Category Taxonomy.html", "/Users/deringezgin/Projects/PaperScope/taxonomy.csv")
