<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Custom agents](README.md) > Packaging and deployment

# Packaging and deployment

## Overview

Custom agent extensions are packaged as `.daz` files and deployed through Krista's catalog system. This page describes the packaging format, deployment workflow, and best practices for testing and production deployment.

## Packaging format

### File format

- **Extension**: `.daz`
- **Naming convention**: `Agent-Domain.daz` or `[YourAgentName]-Agent.daz`
- **Format**: Special archive format recognized by Krista platform

### Package contents

Your `.daz` package should include:

- Compiled extension classes
- Required dependencies (JAR files)
- Configuration files
- Resources (if any)
- Metadata for catalog registration

## Deployment workflow

### Development and testing

Follow this recommended workflow for safe, iterative development:

```
1. Local Development
   ↓
2. Build & Package (.daz)
   ↓
3. Import to Private Catalog
   ↓
4. Test & Validate
   ↓
5. Deploy to Global Catalog
```

### Catalog types

| Catalog Type | Purpose | Visibility | Use Case |
|--------------|---------|------------|----------|
| **Private Catalog** | Development and testing | Your organization only | Internal verification, QA testing |
| **Global Catalog** | Production deployment | All Krista users | Production-ready extensions |

## Step-by-step deployment

### 1. Build and package locally

Ensure your extension is ready for packaging:

```bash
# Build your extension
./gradlew clean build

# Verify the /hostUrl endpoint works
curl -X GET http://localhost:8080/hostUrl

# Package as .daz file
# (Use your build tool or Krista packaging utility)
```

### 2. Import to Private Catalog

1. Navigate to **Catalog Management** in Krista platform
2. Select **Private Catalog**
3. Click **Import Extension**
4. Upload your `.daz` file
5. Wait for import confirmation

### 3. Verify registration

After import, verify your agent appears correctly:

**Check Agent List:**
1. Navigate to **Agent Setup → Agent List**
2. Verify your custom agent appears in the list
3. Check that the agent name and description are correct

**Test Dashboard Embedding:**
1. Go to **Home** page
2. Navigate to **Topic** section
3. Verify your agent's dashboard loads correctly in the iframe
4. Test all interactive features

### 4. Functional testing

Test all catalog requests and agent functionality:

```
✓ Hosting URL endpoint responds correctly
✓ Dashboard loads without errors
✓ All catalog requests execute successfully
✓ Error handling works as expected
✓ Performance meets requirements (< 500ms for /hostUrl)
```

### 5. Deploy to Global Catalog

Once testing is complete:

1. Navigate to **Catalog Management**
2. Select **Global Catalog**
3. Click **Publish Extension**
4. Select your extension from Private Catalog
5. Provide release notes and version information
6. Submit for approval (if required)
7. Monitor deployment status

## Pre-deployment checklist

Before deploying to production, verify:

### Technical requirements

- [ ] `/hostUrl` endpoint returns correct hosting URL
- [ ] Hosting URL is stable and uses HTTPS
- [ ] All catalog requests have unique IDs
- [ ] Domain and ecosystem IDs are correct
- [ ] Extension compiles without errors
- [ ] All dependencies are included in package

### Testing requirements

- [ ] Tested in Private Catalog
- [ ] Dashboard loads correctly in iframe
- [ ] All features work as expected
- [ ] Error handling tested
- [ ] Performance validated
- [ ] Security review completed

### Documentation requirements

- [ ] User documentation prepared
- [ ] API documentation complete
- [ ] Release notes written
- [ ] Known issues documented

## Version management

### Versioning strategy

Use semantic versioning for your agent extensions:

```
MAJOR.MINOR.PATCH

Example: 1.2.3
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes
```

### Updating existing extensions

To update a deployed extension:

1. Increment version number
2. Build and package new version
3. Test in Private Catalog
4. Deploy to Global Catalog
5. Notify users of changes

## Rollback procedure

If issues are discovered after deployment:

1. Navigate to **Catalog Management → Global Catalog**
2. Select the problematic extension
3. Click **Rollback to Previous Version**
4. Confirm rollback
5. Investigate and fix issues
6. Redeploy when ready

## Common deployment issues

### Import fails

**Cause**: Invalid package format or missing dependencies

**Resolution**:
1. Verify `.daz` file is not corrupted
2. Check that all dependencies are included
3. Review build logs for errors
4. Ensure package structure is correct

### Agent doesn't appear in Agent List

**Cause**: Incorrect domain registration

**Resolution**:
1. Verify domain ID matches `catEntryDomain_c54d9930-ea03-4c58-bee6-26f90939171d`
2. Check ecosystem ID is correct
3. Rebuild and reimport extension

### Dashboard fails to load

**Cause**: Incorrect hosting URL or CORS issues

**Resolution**:
1. Test `/hostUrl` endpoint directly
2. Verify hosting URL is accessible
3. Check CORS configuration
4. Review browser console for errors

### Performance issues

**Cause**: Slow `/hostUrl` endpoint or heavy dashboard

**Resolution**:
1. Optimize `/hostUrl` endpoint (target < 500ms)
2. Reduce dashboard resource size
3. Implement caching where appropriate
4. Use CDN for static assets

## Best practices

### 1. Test thoroughly before production

Always test in Private Catalog before deploying to Global Catalog:

```
Private Catalog → Validate → Global Catalog
```

### 2. Use environment-specific configurations

Maintain separate configurations for development, staging, and production:

```java
String hostUrl = getEnvironmentSpecificUrl();
```

### 3. Monitor after deployment

After deploying to Global Catalog:
- Monitor error logs
- Track usage metrics
- Collect user feedback
- Plan iterative improvements

### 4. Maintain backward compatibility

When updating extensions:
- Avoid breaking changes when possible
- Provide migration guides for breaking changes
- Support previous versions during transition period

## See also

- [Building and packaging](../getting-started/BuildingAndPackaging.md)
- [Deployment and configuration](../operations/DeploymentAndConfiguration.md)
- [Troubleshooting](../operations/Troubleshooting.md)



## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../LICENSE).

