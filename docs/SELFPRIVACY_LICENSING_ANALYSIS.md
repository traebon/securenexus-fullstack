# SelfPrivacy Licensing Analysis for SecureNexus Project

**Date:** November 6, 2025
**Purpose:** Legal analysis of using SelfPrivacy code in SecureNexus infrastructure
**License:** AGPL-3.0 (GNU Affero General Public License v3.0)

---

## Executive Summary

⚠️ **Important:** SelfPrivacy is licensed under **AGPL-3.0**, which is a **strong copyleft license** with significant implications for commercial use.

**Key Findings:**
- ✅ You **CAN** use SelfPrivacy code for commercial purposes
- ⚠️ You **MUST** release your source code if you use/modify their code
- ⚠️ You **MUST** use AGPL-3.0 license for derivative works
- ✅ You **CAN** rebrand and use a separate name
- ⚠️ The "network clause" applies - users can request your source code

**Recommendation:** Build inspired by SelfPrivacy but write your own code to avoid AGPL obligations.

---

## What is AGPL-3.0?

### Overview
The **GNU Affero General Public License v3.0** (AGPL-3.0) is one of the strongest copyleft licenses in open source. It's similar to GPL-3.0 but with an additional "network clause" that makes it particularly restrictive for web services.

### Key Characteristics

**Copyleft (Strong):**
- Any derivative work MUST be licensed under AGPL-3.0
- Cannot be relicensed to MIT, Apache, or proprietary
- "Viral" nature spreads to entire codebase

**Network Clause (Critical):**
- If you run AGPL software over a network (web service, API)
- Users accessing it remotely can request the source code
- Closes the "ASP loophole" in GPL-3.0

**Commercial Use:**
- ✅ Allowed - you can charge for services
- ⚠️ But must provide source code to users
- ⚠️ Cannot keep modifications proprietary

---

## Legal Requirements if Using SelfPrivacy Code

### 1. Source Code Disclosure ⚠️

**Requirement:**
- You MUST provide the complete source code
- To anyone who uses your service
- Including all modifications you made

**What This Means:**
```
If you modify SelfPrivacy app and deploy it:
→ Your clients can request the source code
→ You must provide it (including your changes)
→ They can then redistribute it
→ Your competitors could use your code
```

### 2. License Inheritance ⚠️

**Requirement:**
- Any work based on AGPL code becomes AGPL
- You cannot relicense to a different license
- Entire derivative work must be AGPL-3.0

**What This Means:**
```
If you use SelfPrivacy API code:
→ Your entire API must be AGPL-3.0
→ Cannot be proprietary
→ Cannot use dual-licensing
→ Cannot mix with proprietary components
```

### 3. Attribution Requirements ✅

**Requirement:**
- Must retain original copyright notices
- Must credit SelfPrivacy authors
- Must include copy of AGPL-3.0 license

**What This Means:**
```
Your app must say:
"Based on SelfPrivacy by [authors]"
"Licensed under AGPL-3.0"
```

### 4. Network Clause (Most Important) ⚠️⚠️

**Requirement:**
- If users interact with modified AGPL software over network
- They can request the complete source code
- You must provide it within 30 days

**What This Means:**
```
Client uses your SecureNexus app:
→ Connects to your API
→ Client can request API source code
→ You must provide it
→ Client can run their own version
→ Client can share with others
```

---

## Scenarios: What You Can and Cannot Do

### ❌ CANNOT DO (Without Source Release)

**1. Use SelfPrivacy Code Directly**
```
✗ Fork SelfPrivacy app
✗ Modify it for SecureNexus
✗ Keep modifications private
✗ Charge clients without giving source
```

**2. Build Proprietary Service on SelfPrivacy**
```
✗ Use SelfPrivacy API code
✗ Add proprietary features
✗ Sell as closed-source SaaS
✗ Prevent clients from self-hosting
```

**3. Mix AGPL with Proprietary Code**
```
✗ Use SelfPrivacy GraphQL implementation
✗ Add proprietary billing module
✗ Keep billing code closed-source
```

### ✅ CAN DO (With Conditions)

**1. Use and Modify SelfPrivacy Code**
```
✓ Fork and modify the code
✓ Add your features
✓ Rebrand as "SecureNexus Control"
✓ Charge for your service

BUT MUST:
- Release ALL source code (including modifications)
- Use AGPL-3.0 license
- Provide source to all users
- Allow users to redistribute
```

**2. Commercial Use with Open Source**
```
✓ Deploy for clients
✓ Charge monthly fees
✓ Run as business

BUT MUST:
- Publish source code publicly
- Allow clients to self-host
- Cannot prevent competition using your code
```

**3. Learn from SelfPrivacy**
```
✓ Study their architecture
✓ Understand their approach
✓ Build similar features
✓ Use same tech stack (Flutter, GraphQL)

BUT:
- Write your own code from scratch
- Don't copy/paste their code
- This avoids AGPL entirely
```

---

## Comparison: Using vs. Building Inspired By

### Option A: Fork SelfPrivacy (Use Their Code)

**Pros:**
- ✅ Faster development (existing codebase)
- ✅ Proven architecture
- ✅ Active community support
- ✅ Regular updates from upstream

**Cons:**
- ❌ MUST release all source code
- ❌ MUST use AGPL-3.0 license
- ❌ Cannot keep proprietary features
- ❌ Clients can run their own version
- ❌ Competitors can use your code
- ❌ Cannot sell as proprietary SaaS

**Legal Obligations:**
- Publish source on GitHub/GitLab
- Include AGPL-3.0 license file
- Provide source to all users
- Allow redistribution
- Cannot restrict commercial use by others

---

### Option B: Build Inspired By SelfPrivacy (Clean Room)

**Pros:**
- ✅ Keep code proprietary if desired
- ✅ Choose your own license (MIT, proprietary, etc.)
- ✅ No source code disclosure required
- ✅ Protect competitive advantage
- ✅ Full control over features
- ✅ Can mix proprietary components

**Cons:**
- ❌ More development time (start from scratch)
- ❌ No upstream updates
- ❌ Must solve problems yourself

**What You Can Use:**
- ✅ Same architecture concepts (Flutter + GraphQL)
- ✅ Similar UI/UX design (not code)
- ✅ Same tech stack choices
- ✅ Similar feature set
- ❌ **Cannot copy code directly**

**How to Stay Legal:**
1. Don't look at SelfPrivacy source code while coding
2. Only use public documentation and demos
3. Write all code yourself (or with Claude's help)
4. Use same libraries (Flutter, strawberry-graphql, etc.)
5. Implement similar features differently

---

## Rebranding Under AGPL-3.0

### Can You Use a Different Name?

**YES** - You can rebrand:
- ✅ Change app name to "SecureNexus Control"
- ✅ Replace logos and branding
- ✅ Modify UI colors and styling
- ✅ Add your company name

**BUT MUST:**
- ⚠️ Keep "Based on SelfPrivacy" attribution
- ⚠️ Include original copyright notices
- ⚠️ Link to SelfPrivacy project
- ⚠️ Maintain AGPL-3.0 license

### Example Attribution

**Required in App:**
```
SecureNexus Control
Based on SelfPrivacy (https://selfprivacy.org)
Copyright (C) 2023 SelfPrivacy Authors

This program is free software: you can redistribute it
and/or modify it under the terms of the GNU Affero
General Public License as published by the Free Software
Foundation, version 3.

Source code: https://github.com/yourusername/securenexus-control
```

---

## Business Implications

### If Using SelfPrivacy Code (AGPL-3.0)

**Business Model:**
```
Revenue: Service fees, hosting, support
Source Code: Publicly available
Competition: Others can use your code
Clients: Can self-host for free
```

**Example:**
- You charge $500/month per client
- Client pays for convenience and support
- But client can request source code
- Client can run it themselves if they want
- Competitor can use your improvements

**Similar Companies Using AGPL:**
- GitLab (was AGPL, now MIT)
- MongoDB (SSPL, similar to AGPL)
- Grafana (AGPL for core)
- Nextcloud (AGPL)

**Model:** "Open core" - charge for hosting, support, extras

---

### If Building From Scratch (Your License)

**Business Model:**
```
Revenue: Service fees, licensing
Source Code: Proprietary (optional)
Competition: Protected by copyright
Clients: Must use your service
```

**Example:**
- You charge $500/month per client
- Source code remains private
- Clients cannot self-host
- Competitive advantage protected
- Can add premium features

**License Options:**
- **Proprietary:** Closed source (full control)
- **MIT/Apache:** Open source but permissive
- **Dual License:** Open for free, paid for commercial
- **AGPL-3.0:** Match SelfPrivacy (if you want)

---

## Recommendations

### Recommended Approach: Build Inspired (Clean Room)

**Why:**
1. **Legal Safety:** No AGPL obligations
2. **Business Control:** Keep code private if desired
3. **Competitive Advantage:** Protect your innovations
4. **Flexibility:** Choose your own license
5. **Freedom:** No source disclosure requirements

**How:**
1. Study SelfPrivacy architecture (public docs only)
2. Plan your own implementation
3. Write code from scratch with Claude's help
4. Use same tech stack (Flutter, GraphQL, Python)
5. Implement similar features differently
6. Choose your license (MIT, Apache, proprietary)

**Timeline:**
- Similar to building from scratch
- ~5 months for full implementation
- But you own everything

---

### Alternative: Use SelfPrivacy Code (If You Want Open Source)

**When This Makes Sense:**
- You want to be fully open source
- You're okay with source disclosure
- You value community contributions
- You're not concerned about competition
- You want to give back to open source

**Business Model:**
- "Open core" model
- Charge for hosting, support, managed service
- Premium features can be proprietary add-ons
- Similar to GitLab, Nextcloud business models

**Requirements:**
- Publish all code on GitHub
- Use AGPL-3.0 license
- Provide source to users
- Allow redistribution
- Accept that competitors can use your code

---

## Legal Checklist

### If Using SelfPrivacy Code (AGPL-3.0)

- [ ] Fork repository and preserve LICENSE file
- [ ] Include AGPL-3.0 license in your app
- [ ] Add attribution to SelfPrivacy authors
- [ ] Publish your source code publicly
- [ ] Document how to request source code
- [ ] Ensure all modifications are AGPL-3.0
- [ ] Remove any proprietary components
- [ ] Test that source code builds correctly
- [ ] Create documentation for self-hosting
- [ ] Set up process to handle source requests

### If Building Inspired (Clean Room)

- [ ] Document that this is independent work
- [ ] Do not copy any SelfPrivacy code
- [ ] Only reference public documentation
- [ ] Write all code yourself
- [ ] Choose your own license
- [ ] No attribution required (but nice to acknowledge inspiration)
- [ ] Can keep source private
- [ ] No obligation to provide source to users

---

## Example Scenarios

### Scenario 1: SaaS Business (Proprietary)

**Goal:** Build closed-source SaaS for accounting firms

**Recommended:**
- ❌ Don't use SelfPrivacy code (AGPL incompatible)
- ✅ Build inspired by their architecture
- ✅ Write your own implementation
- ✅ Use proprietary license
- ✅ Keep source code private

**Rationale:** AGPL would force you to release source to all clients, defeating the proprietary model.

---

### Scenario 2: Open Source Project

**Goal:** Build open-source tool for community

**Options:**
1. **Fork SelfPrivacy (AGPL-3.0)**
   - Fast development
   - Must stay AGPL-3.0
   - Contribute back to upstream

2. **Build New (MIT/Apache)**
   - More work upfront
   - More permissive license
   - Wider adoption potential

**Recommended:** If purely open source, forking SelfPrivacy is fine. If you might want to commercialize later, build new with MIT/Apache.

---

### Scenario 3: Enterprise On-Premise

**Goal:** Install on client's infrastructure

**With SelfPrivacy Code (AGPL):**
- ✅ Can install on client's servers
- ⚠️ Must provide source code to client
- ⚠️ Client can modify and redistribute
- ⚠️ Client doesn't need to pay for future updates

**Building New (Proprietary):**
- ✅ Can install on client's servers
- ✅ Source code stays private
- ✅ Client must pay for updates
- ✅ License controls usage

**Recommended:** Build new if you want to protect IP and recurring revenue.

---

## Technical Implications

### Using SelfPrivacy Code

**What You Get:**
- Complete Flutter app structure
- GraphQL schema and resolvers
- Authentication flow
- UI components
- Service management logic
- Backup systems
- User management

**What You Must Share:**
- All your modifications
- Any new features you add
- Integration code
- Custom modules
- Configuration management
- Everything under one AGPL license

### Building Inspired

**What You Create:**
- Your own Flutter app
- Your own GraphQL schema
- Your own authentication
- Your own UI components
- Similar but not copied

**What You Keep:**
- All your code (private or open)
- Your business logic
- Your innovations
- Your competitive advantage
- Choice of license

---

## Cost-Benefit Analysis

### Forking SelfPrivacy (AGPL-3.0)

**Costs:**
- Source code disclosure
- AGPL license requirements
- Competition can use your code
- Clients can self-host
- Cannot build proprietary features

**Benefits:**
- Faster initial development (~30% faster)
- Proven architecture
- Community support
- Regular upstream updates
- Open source credibility

**Estimated Savings:** $30k-40k in development costs
**Long-term Risk:** Loss of competitive advantage

---

### Building Inspired (Clean Room)

**Costs:**
- Longer development time
- No upstream updates
- Must solve all problems yourself
- Higher initial investment

**Benefits:**
- Full control
- License flexibility
- Code protection
- Competitive advantage
- No disclosure obligations

**Estimated Additional Cost:** $30k-40k
**Long-term Value:** Protected IP, higher margins

---

## Conclusion

### The Legal Answer

**Can you use SelfPrivacy code?**
- ✅ YES - but with significant restrictions (AGPL-3.0)

**Can you rebrand it?**
- ✅ YES - but must maintain AGPL license and attribution

**Can you keep it proprietary?**
- ❌ NO - not if using their code

### The Business Answer

**Recommended: Build Inspired (Clean Room)**

**Why:**
1. More control over your business
2. Protect competitive advantage
3. No forced source disclosure
4. License flexibility
5. Only ~30% more development time

**How:**
1. Study SelfPrivacy architecture (concepts only)
2. Plan your own implementation
3. Write code from scratch (with Claude)
4. Use similar tech stack
5. Choose your license

### The Practical Answer

**Start with Prototype (Clean Room):**
1. Build minimal API + app (2-3 weeks)
2. Prove the concept works
3. Evaluate if full development makes sense
4. If yes, continue building your own
5. You own everything, no restrictions

---

## Next Steps

### If You Want to Proceed

**Option 1: Use SelfPrivacy Code (AGPL)**
1. Fork their repositories
2. Read AGPL-3.0 license carefully
3. Plan how to comply with obligations
4. Decide if open source model works for you
5. Set up public repository
6. Begin development

**Option 2: Build Inspired (Recommended)**
1. Review SelfPrivacy architecture (concepts)
2. Design your own implementation
3. Start with prototype (2-3 weeks)
4. Choose your license
5. Begin clean-room development
6. Maintain independence

### Questions to Consider

1. **Do you want your code to be open source?**
   - Yes → AGPL is fine
   - No → Build your own

2. **Are you okay with clients self-hosting?**
   - Yes → AGPL is fine
   - No → Build your own

3. **Do you want to protect competitive advantage?**
   - Yes → Build your own
   - No → AGPL is fine

4. **Do you value speed over control?**
   - Speed → Fork SelfPrivacy
   - Control → Build your own

---

## Legal Disclaimer

**This is not legal advice.** This document provides general information about AGPL-3.0 license implications. For specific legal guidance about your situation, consult with a qualified attorney specializing in open source licensing.

**Key Contacts:**
- **Software Freedom Law Center:** https://softwarefreedom.org
- **Open Source Initiative:** https://opensource.org
- **FSF Licensing:** https://www.fsf.org/licensing

---

**Document Created:** November 6, 2025
**License Analysis:** AGPL-3.0
**Recommendation:** Build inspired by SelfPrivacy, but write your own code
**Next Action:** Decide on approach and proceed with prototype
