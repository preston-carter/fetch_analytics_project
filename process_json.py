import json

# Func to flatten MongoDB objects but preserve arrays for BigQuery
def flatten_mongo_object(obj, prefix=''):
    if isinstance(obj, dict):
        new_obj = {}
        for key, value in obj.items():
            if isinstance(value, dict):
                if "$date" in value:
                    new_obj[key] = value["$date"]
                elif "$oid" in value:
                    new_obj[key] = value["$oid"]
                elif "$ref" in value and "$id" in value:
                    if isinstance(value["$id"], dict) and "$oid" in value["$id"]:
                        new_obj[key] = value["$id"]["$oid"]
                    else:
                        new_obj[key] = value["$id"]
                else:
                    # Handle nested objects
                    nested_obj = flatten_mongo_object(value)
                    # If nested object is a dict, flatten with dot notation
                    if isinstance(nested_obj, dict):
                        for nested_key, nested_value in nested_obj.items():
                            new_obj[f"{key}.{nested_key}"] = nested_value
                    else:
                        new_obj[key] = nested_obj
            elif isinstance(value, list):
                # Keep arrays as arrays, but flatten their contents
                new_obj[key] = [flatten_mongo_object(item) for item in value]
            else:
                new_obj[key] = value
        return new_obj
    elif isinstance(obj, list):
        return [flatten_mongo_object(item) for item in obj]
    return obj

# Func to process each json file and parse them properly for BigQuery
def process_json_file(filename):
    # Read all lines and parse each line as JSON
    with open(filename, 'r') as file:
        objects = []
        for line in file:
            if line.strip():
                obj = json.loads(line)
                flattened_obj = flatten_mongo_object(obj)
                objects.append(flattened_obj)
    
    # Write each object on a new line
    output_filename = filename.replace('.json', '_processed.json')
    with open(output_filename, 'w') as file:
        for obj in objects:
            json_line = json.dumps(obj)
            file.write(json_line + '\n')
    
    print(f"Created {output_filename} with {len(objects)} objects")

# Parse files
process_json_file('brands.json')
process_json_file('receipts.json')
process_json_file('users.json')