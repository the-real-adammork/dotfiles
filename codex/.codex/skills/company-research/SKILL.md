---
name: company-research
description: Company research workflow for building a sourced brief from a company URL or domain. Use when Codex is asked to investigate what a company does, its products, estimated market size, employee count, technology stack or likely stack, hiring and job needs, future market opportunities, competitors, or ideal customer profile. This skill coordinates parallel research agents when sub-agent tools are available and then synthesizes a concise evidence-backed report.
---

# Company Research

## Overview

Research a company from a URL by splitting discovery into focused workstreams, grounding claims in current sources, and clearly separating sourced facts from estimates and inferences.

Treat explicit invocation of this skill as permission to use parallel research agents when sub-agent tools are available. If sub-agents are unavailable, execute the same workstreams locally and keep the same source discipline.

Before final synthesis, read [references/report-template.md](references/report-template.md). Save the completed brief in the current workspace at `docs/breifs/<companyname>/brief.md`, where `<companyname>` is a lowercase filesystem-safe slug based on the company name or domain.

## Intake

Start by normalizing the target:

- Capture the provided URL, canonical domain, legal/company name, product/brand names, headquarters if discoverable, and whether the company appears public, private, acquired, shut down, or stealth.
- Browse the official website first. Use the homepage, product pages, pricing, docs, blog/changelog, careers page, security/trust pages, and press/investor pages when available.
- Check whether the URL is a product, parent company, subsidiary, or redirect. If identity is ambiguous, state the ambiguity and resolve it with evidence before deeper research.
- Keep a dated source log while researching. Prefer current sources and include dates for volatile information such as employee count, funding, market size, leadership, open jobs, and product availability.

## Source Rules

Use browsing for this skill. Company, jobs, market, product, and technology information changes frequently.

Prefer sources in this order:

1. Official company sources: website, docs, pricing, careers, blog, changelog, security pages, investor relations, annual reports, SEC filings.
2. Primary ecosystem sources: app stores, GitHub orgs, package registries, standards directories, partner marketplaces, job boards that host the company's actual postings.
3. Reputable secondary sources: analyst reports, credible news, market research summaries, funding databases, review sites, traffic/company databases.
4. Inferences from observable evidence: job descriptions, client-side assets, HTTP headers, integrations, docs, DNS records, public repos, SDKs, and customer-facing workflows.

Do not present unsupported guesses as facts. Label confidence as `High`, `Medium`, or `Low` for employee count, market size, technology stack, and future opportunities. Provide ranges when exact numbers are unavailable.

## Parallel Workstreams

Spawn separate research agents for independent workstreams when the available tools support it. Give each agent the company URL, a narrow brief, and instructions to return sources with dates. Avoid duplicate work across agents.

Use this default split:

- **Company and Product Agent**: Determine what the company does, target users, business model, pricing signals, all discoverable products/modules, integrations, platforms, geographies, and product maturity.
- **Market and Competition Agent**: Estimate market category, TAM/SAM/SOM if possible, growth drivers, competitors, substitutes, category trends, and regulatory or macro constraints.
- **Technology and Hiring Agent**: Identify confirmed and likely technologies, cloud/data/AI/security stack, engineering practices, public repos, SDKs/APIs, current job openings, role families, seniority, locations, and skills requested.
- **Customer and Opportunity Agent**: Infer ideal customer profile, buyer personas, use cases, pain points, adoption triggers, expansion paths, future market opportunities, and likely risks.

For large or complex companies, add focused agents for regional markets, public filings, pricing/packaging, or developer ecosystem. For very small companies, combine workstreams but still keep the findings separated.

## Agent Brief Pattern

Use a brief like this for each sub-agent:

```text
Research <company name/domain> from <URL> for the <workstream name> workstream.

Return:
- 5-10 bullet findings, each with source links and dates when available.
- Explicit confidence labels for estimates or inferences.
- Contradictions or uncertainty to resolve in synthesis.
- Source list with official sources first.

Do not write the final company brief. Focus only on your assigned workstream.
```

## Research Methods

Use the following tactics as applicable:

- Product inventory: inspect navigation, sitemap, docs, pricing, support center, changelog, API docs, integration directories, app stores, marketplaces, and screenshots.
- Employee count: compare LinkedIn/company database ranges, careers page scale, funding stage, leadership/team pages, layoffs/news, and public filings. Prefer a range and timestamp.
- Market size: define the category before sizing it. Use public analyst summaries, company filings, investor decks, competitor filings, government/industry data, and bottom-up assumptions. State whether the number is TAM, SAM, SOM, revenue pool, or adjacent market.
- Technology stack: prioritize direct evidence from docs, public repos, SDKs, engineering blog posts, job postings, client-side assets, HTTP headers, status pages, security pages, subdomains, and vendor case studies. Mark job-posting-derived stack as likely unless the posting confirms production use.
- Job needs: review careers pages and current postings. Summarize role families, repeated skill requirements, seniority, locations/remote policy, GTM roles, and what hiring implies about business priorities.
- ICP: infer from customer logos, case studies, pricing, compliance posture, integrations, sales motion, product language, implementation complexity, and support model.
- Future opportunities: connect evidence from market growth, product gaps, customer segments, competitor moves, technology shifts, regulation, and distribution channels. Separate attractive opportunities from speculative bets.

## Synthesis

After agents finish, reconcile their source lists and contradictions before writing the report.

Prioritize:

- Current official facts over stale secondary summaries.
- Ranges over false precision.
- Direct evidence over inferred evidence.
- Clear uncertainty over confident filler.

Call out any key unavailable data, paywalled data, or sources that could not be verified. Include a "why this matters" angle for market, hiring, technology, and ICP findings so the report is useful for sales, investing, partnership, or product strategy.

Use [references/report-template.md](references/report-template.md) for the final structure unless the user asks for a different format.

## Output File

Always save the final brief to `docs/breifs/<companyname>/brief.md` in the active workspace.

Use this naming rule:

- Prefer the company name from official sources, lowercased and converted to hyphen-case.
- If the company name is unclear, use the canonical domain without `www.` and replace non-alphanumeric characters with hyphens.
- Keep only lowercase letters, digits, and hyphens. Collapse repeated hyphens and trim leading or trailing hyphens.

Create the directory if needed. After saving, mention the file path in the final response.
