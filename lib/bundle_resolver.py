#!/usr/bin/env python3
import sys
import yaml # We need to handle the case where PyYAML might not be installed, but let's assume standard python3 environment first or use a simple parser.
# Wait, standard python3 doesn't have pyyaml. I should use a simple parser since I cannot guarantee pip install.
# Since the requirement was "standard python3", I will implement a simple parser for the specific subset of YAML we use.

import argparse
from collections import defaultdict, deque

def simple_yaml_parser(file_path):
    """
    Parses a simplified YAML structure for bundles.
    Supports:
    tools:
      - name
      - name:
          depends_on: [dep1, dep2]
          skip: true/false
    """
    with open(file_path, 'r') as f:
        lines = f.readlines()

    bundle = {'tools': []}
    current_tool = None
    in_tools_section = False
    
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue
            
        if stripped.startswith('tools:'):
            in_tools_section = True
            continue
            
        if in_tools_section:
            # Check for list item
            if line.strip().startswith('- '):
                # New tool
                content = line.strip()[2:]
                if ':' in content:
                    tool_name = content.split(':')[0].strip()
                    current_tool = {'name': tool_name, 'depends_on': [], 'skip': False}
                    bundle['tools'].append(current_tool)
                else:
                    tool_name = content.strip()
                    current_tool = {'name': tool_name, 'depends_on': [], 'skip': False}
                    bundle['tools'].append(current_tool)
                    
            # Check for attributes of current tool (indentation)
            elif current_tool and line.startswith(' '):
                if 'depends_on:' in stripped:
                    # Handle invalid inline list format like [a, b] for now by just looking at next lines if empty
                    # Or handle explicit list format
                    parts = stripped.split('depends_on:')
                    if len(parts) > 1 and parts[1].strip():
                         # Inline list: [a, b]
                         deps_str = parts[1].strip().strip('[]')
                         if deps_str:
                             current_tool['depends_on'] = [d.strip() for d in deps_str.split(',') if d.strip()]
                elif 'skip:' in stripped:
                    # Parse skip parameter
                    parts = stripped.split('skip:')
                    if len(parts) > 1:
                        skip_val = parts[1].strip().lower()
                        current_tool['skip'] = skip_val in ['true', 'yes', '1']
                elif stripped.startswith('- '):
                     # List item under depends_on (assuming it's the active key)
                     # ideally we track indentation levels, but for this specific format:
                     dep = stripped[2:].strip()
                     current_tool['depends_on'].append(dep)

    return bundle

def topological_sort(tools):
    # tools is a list of dicts: {'name': 'foo', 'depends_on': ['bar']}
    
    # Build graph
    graph = defaultdict(list)
    in_degree = defaultdict(int)
    all_tools = set()
    
    # Map name back to tool object if needed, or just track names
    tool_map = {t['name']: t for t in tools}
    
    for tool in tools:
        name = tool['name']
        all_tools.add(name)
        if name not in in_degree:
            in_degree[name] = 0
            
        for dep in tool.get('depends_on', []):
            if dep not in tool_map:
                # If dependency is not in valid tools, we might error or ignore. 
                # Let's error strictly.
                sys.stderr.write(f"Error: Tool '{name}' depends on unknown tool '{dep}'\n")
                sys.exit(1)
                
            graph[dep].append(name)
            in_degree[name] += 1
            all_tools.add(dep) # Should be already added but just in case
            
    # Kahn's Algorithm
    queue = deque([node for node in all_tools if in_degree[node] == 0])
    result = []
    
    while queue:
        u = queue.popleft()
        result.append(u)
        
        for v in graph[u]:
            in_degree[v] -= 1
            if in_degree[v] == 0:
                queue.append(v)
                
    if len(result) != len(all_tools):
        sys.stderr.write("Error: Cyclic dependency detected!\n")
        sys.exit(1)
        
    return result

def main():
    if len(sys.argv) != 2:
        print("Usage: bundle_resolver.py <bundle_file>")
        sys.exit(1)
        
    bundle_file = sys.argv[1]
    
    try:
        # Try importing PyYAML if available, else use custom parser
        try:
            import yaml
            with open(bundle_file, 'r') as f:
                data = yaml.safe_load(f)
            
            # Normalize data structure to list of dicts with 'name', 'depends_on', and 'skip'
            # YAML might load as list of strings or dicts
            normalized_tools = []
            if 'tools' in data and data['tools']:
                for item in data['tools']:
                    if isinstance(item, str):
                        normalized_tools.append({'name': item, 'depends_on': [], 'skip': False})
                    elif isinstance(item, dict):
                        # key is name, value is dict of attrs
                        for name, attrs in item.items():
                             # attrs might be None if empty mapping
                            deps = attrs.get('depends_on', []) if attrs else []
                            skip = attrs.get('skip', False) if attrs else False
                            normalized_tools.append({'name': name, 'depends_on': deps, 'skip': skip})
            
        except ImportError:
            # Fallback to simple parser
             data = simple_yaml_parser(bundle_file)
             normalized_tools = data['tools']

        # Filter out skipped tools before processing
        active_tools = [tool for tool in normalized_tools if not tool.get('skip', False)]
        
        execution_order = topological_sort(active_tools)
        
        # Print valid tool names for bash to consume
        for tool in execution_order:
            print(tool)
            
    except Exception as e:
        sys.stderr.write(f"Error resolving bundle: {e}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
