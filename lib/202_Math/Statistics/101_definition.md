# SCR Semantic Library — 202 Math / Statistics

**Document:** `lib/202_Math/Statistics/101_definition.md`  
**Version:** `0.1.0`  
**Status:** Normative semantic definition  
**Domain:** Math / Statistics  
**Parent:** `lib/202_Math/101_definition.md`  
**Authority:** Semantic Computational Runtime (SCR)  

---

## 1. Definition

The **Statistics Domain** defines the science of collecting, analyzing, interpreting, presenting, and organizing quantitative data, including descriptive and inferential statistics.

---

## 2. Fundamental Distinction

> **Statistics is not a mean() function; it is the mathematical inference of population characteristics from sample distributions.**

Mathematical semantics remain authoritative; physical arrays, hardware registers, GPU buffers, and numerical libraries remain subordinate.

---

## 3. Subdomain Invariants

* **STA-INV-001 (Sample Moment Consistency):** Sample variance and higher moments MUST use unbiased estimators where specified.
* **STA-INV-002 (Correlation Boundedness):** Pearson and Spearman correlation coefficients MUST lie strictly within $[-1.0, 1.0]$.
* **STA-INV-003 (Hypothesis Transparency):** Statistical tests MUST declare null hypotheses, significance levels $\alpha$, and test statistics.
