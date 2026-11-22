"""
SecureAI Content Analyzer & Intelligent Security Fallback
========================================================
Provides robust, instant heuristic analysis for SMS and Email messages.
Guarantees that users ALWAYS receive clear, structured, and insightful security
explanations even during network drops, API rate limits, or external LLM outages.
"""

import re
from typing import Tuple, List, Optional
from urllib.parse import urlparse


def sanitize_bracketed_urls(text: str) -> str:
    """
    Separates URLs enclosed in braces or brackets so trailing delimiters
    (such as '}' in '{https://forms.gle/xyz}') are not swallowed as part of the URL path.
    """
    if not text:
        return ""
    cleaned = re.sub(r'(https?://[^\s{}]+)[}]', r'\1 }', text)
    cleaned = re.sub(r'(https?://[^\s\[\]]+)[\]]', r'\1 ]', cleaned)
    cleaned = re.sub(r'(https?://[^\s<>]+)[>]', r'\1 >', cleaned)
    return cleaned


def clean_technical_error(raw_reason: str) -> str:
    """
    Translates raw Python socket/SSL/pool tracebacks into clean, human-readable security notices.
    """
    if not raw_reason:
        return "Unspecified security anomaly"
    
    r_lower = raw_reason.lower()
    if 'ssl' in r_lower or 'certificate_verify_failed' in r_lower or 'tls verification failed' in r_lower:
        return "The destination server presented an invalid or self-signed SSL certificate."
    if 'max retries exceeded' in r_lower or 'connection failed' in r_lower:
        return "Connection to destination host failed or was refused by remote server."
    if 'timeout' in r_lower or 'deadline' in r_lower:
        return "Connection timed out before destination server responded."
    if 'redirect chain exceeded' in r_lower:
        return "Destination used excessive redirect hops (evasion tactic)."
    if 'redirect cycle' in r_lower:
        return "Redirect loop detected between destinations."
    if 'loopback' in r_lower or 'private ip' in r_lower:
        return "Internal network or loopback address blocked by security policy."
    
    # Strip any remaining python class names or socket descriptors
    cleaned = re.sub(r'DeadlineHTTPSConnectionPool\([^)]+\):?\s*', '', raw_reason)
    cleaned = re.sub(r'\(Caused by [^)]+\)', '', cleaned)
    return cleaned.strip() or raw_reason


def analyze_email_heuristics(email_text: str, audit_batch=None) -> Tuple[str, str]:
    """
    Performs deep heuristic security analysis of email text.
    Returns (classification: 'Phishing' | 'Suspicious' | 'Safe', explanation: str).
    """
    text_lower = email_text.lower()
    red_flags: List[str] = []
    
    # 1. Job / Internship / Educational Training Lures
    has_internship_lure = any(k in text_lower for k in (
        'internship', 'training program', 'shortlisted for', 'stipend upto', 
        'stipend up to', 'placement assistance', 'letter of recommendation'
    ))
    has_big_brands = any(k in text_lower for k in ('ibm', 'microsoft', 'google', 'adobe', 'meta'))
    has_free_form = any(k in text_lower for k in ('forms.gle', 'docs.google.com/forms', 'typeform', 'jotform'))
    
    # Check sender header if present in text
    sender_match = re.search(r'[\w.+-]+@([\w-]+\.[\w.-]+)', email_text)
    sender_domain = sender_match.group(1).lower() if sender_match else ""
    
    if has_internship_lure:
        if has_big_brands and sender_domain and not any(b in sender_domain for b in ('ibm.com', 'microsoft.com', 'google.com')):
            red_flags.append(f"Third-Party Sender Mismatch: Claims official programs from IBM, Google, or Microsoft, but originated from an unverified third-party domain (@{sender_domain}).")
        elif has_big_brands:
            red_flags.append("Multi-Brand Overpromising: Offers co-branded certificates from multiple competing tech giants (IBM, Google, Microsoft, Meta), a hallmark of unauthorized training lures.")
        
        if 'shortlisted' in text_lower:
            red_flags.append("Unsolicited Selection Lure: Claims the recipient was shortlisted for a high-stipend program without a verified prior formal application.")
        
        if has_free_form:
            red_flags.append("Unofficial Application Channel: Directs applicants to a public, unauthenticated Google Form rather than an authenticated corporate career portal.")
        
        if 'referral code' in text_lower:
            red_flags.append("Marketing Lure & Referral Tracking: Uses referral codes to track commission-based recruitment under the guise of an official MNC selection.")

    # 2. Fake Invoices / Urgent Wire Transfers
    has_invoice = any(k in text_lower for k in ('invoice', 'overdue invoice', 'billing portal', 'remittance', 'wire transfer', 'banking details'))
    has_urgency = any(k in text_lower for k in ('urgent', 'end of day', 'immediate payment', 'avoid disruption', 'account suspended'))
    if has_invoice and has_urgency:
        red_flags.append("Financial Urgency: Demands immediate review of invoices or financial transactions with short deadlines to pressure the recipient.")
    elif has_invoice:
        red_flags.append("Financial Transaction Reference: Contains requests regarding invoices or payments requiring verification through independent channels.")

    # 3. Credential Harvesting & Account Suspension
    has_cred_prompt = any(k in text_lower for k in ('verify your account', 'password expired', 'unusual activity', 'confirm your identity', 'log in to view'))
    if has_cred_prompt:
        red_flags.append("Credential Harvesting Indicator: Prompts the user to log in, verify credentials, or confirm passwords.")

    # 4. Lottery / Prize / Crypto Scams
    has_lottery = any(k in text_lower for k in ('congratulations you won', 'claim prize', 'gift card', 'crypto deposit', 'double your bitcoin'))
    if has_lottery:
        red_flags.append("Deceptive Reward Lure: Promises unearned financial rewards, lottery prizes, or guaranteed investment returns.")

    # Classify based on findings
    if len(red_flags) >= 2 or has_cred_prompt or (has_invoice and has_urgency):
        classification = "Suspicious" if has_internship_lure else "Phishing"
        formatted_flags = "\n".join([f"• {flag}" for flag in red_flags])
        explanation = (
            f"Social Engineering Analysis:\n"
            f"{formatted_flags}\n"
            f"• Recommendation: Do not share personal documents, payment card details, or credentials through unverified forms."
        )
        return classification, explanation
    elif len(red_flags) == 1:
        return "Suspicious", f"Security Precaution:\n• {red_flags[0]}\n• Recommendation: Independently verify the sender's identity before responding."
    else:
        # Benign check
        return "Safe", (
            "• Routine Communication: The message content does not contain common phishing lures, credential prompts, or coercive language.\n"
            "• Link Verification: Review any embedded links independently before providing personal data."
        )


def analyze_sms_heuristics(sms_text: str, audit_batch=None) -> Tuple[str, str]:
    """
    Performs deep heuristic security analysis of SMS text.
    Returns (classification: 'Spam' | 'Ham', explanation: str).
    """
    text_lower = sms_text.lower()
    red_flags: List[str] = []

    # 1. Package / Smishing Lures
    if any(k in text_lower for k in ('package', 'parcel', 'delivery', 'customs', 'address update', 'redelivery', 'post')):
        red_flags.append("Package Smishing Pattern: Impersonates shipping or postal services to elicit address or payment confirmation.")

    # 2. Financial / Banking Alert Lures
    if any(k in text_lower for k in ('bank', 'blocked', 'suspended', 'transaction of', 'debit card', 'unauthorized')):
        red_flags.append("Banking Coercion: Simulates an urgent security alert regarding bank accounts or payment cards.")

    # 3. Prize / Unsolicited Offers
    if any(k in text_lower for k in ('won', 'claim your', 'free gift', 'stipend', 'selected for', 'earn $', 'earn rs')):
        red_flags.append("Unsolicited Reward / Job Lure: Offers unexpected monetary rewards or unverified employment opportunities.")

    # 4. Urgent Action Demands
    if any(k in text_lower for k in ('immediately', 'urgent', 'within 24 hours', 'click here', 'act now')):
        red_flags.append("Urgent Call to Action: Uses high-pressure language to rush the recipient into opening links.")

    if red_flags:
        formatted_flags = "\n".join([f"• {flag}" for flag in red_flags])
        explanation = f"Message Threat Indicators:\n{formatted_flags}\n• Recommendation: Avoid clicking links or replying with personal information."
        return "Spam", explanation
    else:
        return "Ham", "• Routine Message: The text does not exhibit standard spam keywords, coercive deadlines, or suspicious lures."
