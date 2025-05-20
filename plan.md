# GrantAxis Implementation Plan

## Overview
GrantAxis is a SaaS solution that leverages Titan's Snowflake-IaC engine to eliminate access-right drift in Snowflake environments. This document outlines the implementation strategy and technical architecture.

## Repository Structure
```
grantaxis/
 ├─ apps/
 │   ├─ api/            # FastAPI – multitenant REST/GraphQL
 │   └─ web/            # Next.js landing + console
 ├─ services/
 │   └─ titan-worker/   # Docker image; calls titan CLI
 ├─ third_party/
 │   └─ titan_core/     # All Titan code and LICENSE live here
 ├─ infra/              # Terraform/K8s for prod
 └─ LICENSE, NOTICE …
```

## Core Architecture

### 1. Titan Integration Layer
- Utilize Titan Core as the primary Snowflake-IaC engine
- Implement custom Python wrappers around Titan's core functionality
- Maintain separation between Titan's open-source components and GrantAxis's proprietary features
- Service-to-Titan Interface:
  - Export: `titan export snowflake://$ACCT > baseline.yaml`
  - Policy Injection: `cat policy.yaml >> baseline.yaml`
  - Plan: `titan plan -f merged.yaml -o plan.json`
  - Parse: Extract summary `{high:12, medium:31, low:88}`

### 2. Drift Scanner Component
- **Implementation**: Python service running on 10-minute intervals
- **Core Features**:
  - Compare live grants against data-classification tags
  - Generate detailed diff reports
  - Store scan results in immutable audit logs
- **Technical Stack**:
  - Titan Core for Snowflake resource scanning
  - Custom Python service for drift detection
  - Snowflake stored procedures for efficient grant comparison

### 3. Auto-Revoke Engine
- **Implementation**: Snowflake stored procedures
- **Core Features**:
  - Automated privilege revocation based on drift detection
  - Approval workflow integration
  - Audit trail generation
- **Technical Stack**:
  - Titan Core for grant management
  - Custom stored procedures for revocation logic
  - Snowflake native audit logging

### 4. Alerting System
- **Implementation**: Python service with webhook integration
- **Core Features**:
  - Slack integration with approve/deny buttons
  - Email notifications
  - Teams integration (future)
- **Technical Stack**:
  - FastAPI for webhook endpoints
  - Slack API integration
  - SMTP service for email notifications

### 5. Audit Timeline
- **Implementation**: Snowflake-native logging with export capabilities
- **Core Features**:
  - Immutable audit logs
  - PDF export functionality
  - HTML dashboard (future)
- **Technical Stack**:
  - Snowflake native audit logging
  - PDF generation service
  - React-based dashboard (future)

### 6. PII Tag Import
- **Implementation**: Python service with multiple import methods
- **Core Features**:
  - TAG_REFERENCES integration
  - CSV import capability
  - Google Sheet integration (future)
- **Technical Stack**:
  - Titan Core for tag management
  - Custom import handlers
  - Google Sheets API (future)

## Security Architecture

### 1. Single-Tenant Option
- Isolated Snowflake accounts per customer
- Dedicated Titan Core instances
- No data exfiltration capabilities

### 2. Authentication & Authorization
- SSO integration (SAML/OIDC)
- Role-based access control
- Audit logging for all operations

### 3. Compliance
- SOC 2 Type I certification target
- Immutable audit trails
- Regular security assessments

## Implementation Phases

### Phase 1: Core Infrastructure (Months 1-2)
- [ ] Set up Titan Core integration
- [ ] Implement basic drift scanner
- [ ] Create initial auto-revoke engine
- [ ] Establish basic alerting system

### Phase 2: Enhanced Features (Months 3-4)
- [ ] Implement comprehensive audit timeline
- [ ] Add PII tag import capabilities
- [ ] Enhance alerting system
- [ ] Develop basic dashboard

### Phase 3: Security & Compliance (Months 5-6)
- [ ] Implement SSO
- [ ] Prepare for SOC 2 Type I
- [ ] Enhance security features
- [ ] Complete audit capabilities

### Phase 4: Future Enhancements
- [ ] Teams integration
- [ ] HTML dashboard
- [ ] Google Sheet integration
- [ ] Additional import methods

## Technical Requirements

### Infrastructure
- Snowflake Enterprise Edition
- Python 3.8+
- Titan Core latest version
- Containerized deployment (Docker)

### Dependencies
- FastAPI
- Slack SDK
- Snowflake Connector
- PDF generation libraries
- React (for future dashboard)

## Monitoring & Maintenance

### Health Checks
- Regular Titan Core updates
- Drift scanner performance monitoring
- Alert system reliability checks
- Audit log integrity verification

### Backup & Recovery
- Regular configuration backups
- Audit log archiving
- Disaster recovery procedures

## Success Metrics

### Technical Metrics
- Drift detection accuracy
- Auto-revoke success rate
- Alert delivery reliability
- Audit log completeness

### Business Metrics
- Reduction in manual review time
- Decrease in access-right violations
- Audit preparation time reduction
- Customer satisfaction scores

## Risk Mitigation

### Technical Risks
- Titan Core version compatibility
- Snowflake API rate limits
- Performance impact of frequent scans
- Data classification accuracy

### Business Risks
- Customer adoption rate
- Compliance requirements changes
- Competitive landscape
- Resource constraints

## Documentation

### Technical Documentation
- Architecture diagrams
- API documentation
- Deployment guides
- Troubleshooting guides

### User Documentation
- User guides
- Best practices
- FAQ
- Training materials

## Upgrade Path After Scan MVP

1. **Auto-Revoke (Growth tier)**
   - Expose `titan apply` behind POST `/plans/<id>/apply` with dry-run preview

2. **AI Copilot**
   - Feed exported YAML to LLM
   - Suggest least-privilege templates

3. **Cross-platform**
   - Build BigQueryAdapter mapping into Titan resource model 