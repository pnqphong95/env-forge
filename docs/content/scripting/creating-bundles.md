---
sidebar_position: 3
---

# Creating Bundles

Bundles are YAML files that define collections of tools with their dependencies. Learn how to create custom bundles for your needs.

## Bundle Structure

```yaml
name: "Bundle Name"
description: "Bundle description"
tools:
  - tool-name:
      depends_on:
        - dependency1
        - dependency2
  - another-tool:
```

## Basic Bundle

### Minimal Bundle

```yaml
name: "Minimal Setup"
description: "Essential tools only"
tools:
  - git:
  - build-essential:
```

### With Dependencies

```yaml
name: "Web Development"
description: "Full-stack web development environment"
tools:
  - build-essential:
  - nodejs:
      depends_on:
        - build-essential
  - docker:
      depends_on:
        - build-essential
```

## Step-by-Step Guide

### 1. Create Bundle File

```bash
cd ~/.envforge/bundles
touch mybundle.yaml
```

### 2. Define Metadata

```yaml
name: "My Custom Bundle"
description: "Custom tools for my workflow"
```

### 3. Add Tools

```yaml
tools:
  - git:
  - build-essential:
  - nodejs:
```

### 4. Add Dependencies

```yaml
tools:
  - build-essential:
  - nodejs:
      depends_on:
        - build-essential
  - vscode:
      depends_on:
        - nodejs
```

### 5. Test the Bundle

```bash
# Preview
envforge up --env mybundle.yaml --dry-run

# Install
envforge up --env mybundle.yaml
```

## Real-World Examples

### Example 1: Backend Development

```yaml
name: "Backend Development"
description: "Tools for backend development with Node.js and databases"
tools:
  - build-essential:
  - git:
  - nodejs:
      depends_on:
        - build-essential
  - docker:
      depends_on:
        - build-essential
  - postgresql:
      depends_on:
        - build-essential
```

### Example 2: Frontend Development

```yaml
name: "Frontend Development"
description: "Modern frontend development environment"
tools:
  - git:
  - nodejs:
      depends_on:
        - build-essential
  - build-essential:
  - vscode:
```

### Example 3: DevOps Tools

```yaml
name: "DevOps Toolkit"
description: "Essential DevOps and infrastructure tools"
tools:
  - git:
  - docker:
      depends_on:
        - build-essential
  - build-essential:
  - kubectl:
      depends_on:
        - docker
  - terraform:
  - ansible:
      depends_on:
        - build-essential
```

### Example 4: Mobile Development

```yaml
name: "Mobile Development"
description: "Android and React Native development"
tools:
  - build-essential:
  - git:
  - nodejs:
      depends_on:
        - build-essential
  - java:
      depends_on:
        - build-essential
  - android-sdk:
      depends_on:
        - java
  - react-native-cli:
      depends_on:
        - nodejs
        - android-sdk
```

## Dependency Management

### Linear Dependencies

```yaml
tools:
  - tool-a:
  - tool-b:
      depends_on:
        - tool-a
  - tool-c:
      depends_on:
        - tool-b
```

Execution order: `tool-a` → `tool-b` → `tool-c`

### Parallel Dependencies

```yaml
tools:
  - base:
  - tool-a:
      depends_on:
        - base
  - tool-b:
      depends_on:
        - base
  - tool-c:
      depends_on:
        - base
```

Execution order: `base` → `tool-a`, `tool-b`, `tool-c` (parallel)

### Complex Dependencies

```yaml
tools:
  - build-essential:
  - git:
  - nodejs:
      depends_on:
        - build-essential
  - docker:
      depends_on:
        - build-essential
  - vscode:
      depends_on:
        - nodejs
        - docker
```

Execution order:
1. `build-essential`, `git` (parallel)
2. `nodejs`, `docker` (parallel, after build-essential)
3. `vscode` (after nodejs and docker)

## Advanced Features

### Optional Tools with Skip

You can conditionally skip tools (requires custom implementation):

```yaml
tools:
  - docker:
      skip: ${SKIP_DOCKER:-false}
```

### Environment-Specific Bundles

Create bundles for different environments:

**bundles/dev.yaml**:
```yaml
name: "Development Environment"
tools:
  - git:
  - nodejs:
  - vscode:
```

**bundles/prod.yaml**:
```yaml
name: "Production Environment"
tools:
  - git:
  - nodejs:
  - docker:
```

### Layered Bundles

Create base bundles and extend them:

**bundles/base.yaml**:
```yaml
name: "Base Tools"
tools:
  - git:
  - build-essential:
```

**bundles/extended.yaml**:
```yaml
name: "Extended Tools"
tools:
  - git:
  - build-essential:
  - nodejs:
      depends_on:
        - build-essential
  - docker:
      depends_on:
        - build-essential
```

## Best Practices

### 1. Use Descriptive Names

```yaml
name: "Full-Stack Web Development"
description: "Complete environment for React and Node.js development"
```

### 2. Group Related Tools

```yaml
# Database tools together
tools:
  - postgresql:
  - mysql:
  - mongodb:
```

### 3. Declare All Dependencies

```yaml
tools:
  - vscode:
      depends_on:
        - nodejs  # Explicit dependency
```

### 4. Order Tools Logically

Put base tools first:

```yaml
tools:
  - build-essential:  # Base
  - git:              # Base
  - nodejs:           # Higher level
      depends_on:
        - build-essential
```

### 5. Test Incrementally

Start small and add tools gradually:

```bash
# Test with minimal bundle first
envforge up --env minimal.yaml

# Then add more tools
envforge up --env full.yaml
```

## Common Patterns

### Pattern 1: Base + Specialized

```yaml
name: "Python Development"
tools:
  # Base tools
  - build-essential:
  - git:
  
  # Python-specific
  - python3:
      depends_on:
        - build-essential
  - pip:
      depends_on:
        - python3
  - virtualenv:
      depends_on:
        - pip
```

### Pattern 2: Multi-Language Support

```yaml
name: "Polyglot Development"
tools:
  - build-essential:
  - git:
  
  # Node.js
  - nodejs:
      depends_on:
        - build-essential
  
  # Python
  - python3:
      depends_on:
        - build-essential
  
  # Go
  - golang:
      depends_on:
        - build-essential
```

### Pattern 3: Tool + Configuration

```yaml
name: "Configured Environment"
tools:
  - git:
  - git-config:  # Custom tool for git configuration
      depends_on:
        - git
  - docker:
  - docker-config:  # Custom tool for docker setup
      depends_on:
        - docker
```

## Troubleshooting

### Circular Dependencies

❌ **Wrong**:
```yaml
tools:
  - tool-a:
      depends_on:
        - tool-b
  - tool-b:
      depends_on:
        - tool-a
```

✅ **Correct**:
```yaml
tools:
  - base:
  - tool-a:
      depends_on:
        - base
  - tool-b:
      depends_on:
        - base
```

### Missing Dependencies

❌ **Wrong**:
```yaml
tools:
  - vscode:  # Needs nodejs but not declared
```

✅ **Correct**:
```yaml
tools:
  - nodejs:
  - vscode:
      depends_on:
        - nodejs
```

## Testing Bundles

### Dry Run

Preview without installing:

```bash
envforge up --env mybundle.yaml --dry-run
```

### Incremental Testing

Test tools individually first:

```bash
./tools/mytool.sh
```

Then test in bundle:

```bash
envforge up --env mybundle.yaml
```

### Reset and Retry

If something fails:

```bash
envforge up --env mybundle.yaml --reset-state
```

## Next Steps

- [**Creating Tools**](creating-tools.md) - Build custom tools for your bundles
- [**How It Works**](how-it-works.md) - Understand dependency resolution
- [**Customization**](../customization/custom-bundles.md) - Advanced bundle customization
