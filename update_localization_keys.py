#!/usr/bin/env python3

import os
import re

# Mapping of old keys to new keys (full sentences)
key_mappings = {
    # App Name & Navigation
    'app_name': 'Lumen',
    'settings': 'Settings',
    'done': 'Done',
    'cancel': 'Cancel',
    'ok': 'OK',
    'retry': 'Retry',
    'continue': 'Continue',
    'back': 'Back',
    'next': 'Next',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'close': 'Close',
    
    # Wallet Main Screen
    'send': 'Send',
    'receive': 'Receive',
    'balance': 'Balance',
    'payment_history': 'Payment History',
    'wallet_info': 'Wallet Info',
    
    # Payment States
    'pending': 'Pending',
    'completed': 'Completed',
    'failed': 'Failed',
    'sent': 'Sent',
    'received': 'Received',
    'created': 'Created',
    'timed_out': 'Timed Out',
    'refundable': 'Refundable',
    'refund_pending': 'Refund Pending',
    'waiting_fee_acceptance': 'Waiting Fee Acceptance',
    
    # Send Payment
    'send_payment': 'Send Payment',
    'paste_invoice': 'Paste Invoice',
    'scan_qr': 'Scan QR',
    'amount': 'Amount',
    'description': 'Description',
    'prepare_payment': 'Prepare Payment',
    'send_now': 'Send Now',
    'payment_details': 'Payment Details',
    'fee_details': 'Fee Details',
    
    # Receive Payment
    'receive_payment': 'Receive Payment',
    'create_invoice': 'Create invoice',
    'invoice_created': 'Invoice Created',
    'you_receive': 'You receive',
    'service_fee': 'Service fee',
    'copy_invoice': 'Copy Invoice',
    'share_invoice': 'Share Invoice',
    
    # Payment History
    'filter': 'Filter',
    'all_payments': 'All',
    'sent_payments': 'Sent',
    'received_payments': 'Received',
    'pending_payments': 'Pending',
    'completed_payments': 'Completed',
    'failed_payments': 'Failed',
    
    # Refunds
    'get_money_back': 'Get Money Back',
    'money_to_get_back': 'Money to Get Back',
    'payment_failed': 'Payment Failed',
    'get_your_money_back': 'Get Your Money Back',
    'money_sent_successfully': 'Money Sent Successfully! 🎉',
    'great': 'Great!',
    'refund_success_message': 'Your money has been sent back to your Bitcoin wallet. It should arrive within the selected timeframe.',
    'refund_explanation': 'These payments didn\'t go through. Tap \'Get Money Back\' to return the funds to your Bitcoin wallet.',
    
    # Settings
    'currency': 'Currency',
    'language': 'Language',
    'security': 'Security',
    'about': 'About',
    'logout': 'Logout',
    'delete_wallet': 'Delete Wallet',
    'export_seed': 'Export Seed Phrase',
    'import_wallet': 'Import Wallet',
    'search_currencies': 'Search currencies...',
    'loading_currencies': 'Loading currencies...',
    
    # Onboarding
    'welcome_to_lumen': 'Welcome to Lumen!',
    'your_wallet_is_ready': 'Your Lightning wallet is ready to use',
    'start_using_lumen': 'Start Using Lumen',
    'create_new_wallet': 'Create New Wallet',
    'import_existing_wallet': 'Import Existing Wallet',
    'wallet_choice_title': 'Choose Wallet Option',
    'wallet_choice_subtitle': 'Create a new wallet or import an existing one',
    
    # Connection Status
    'connected': 'Connected',
    'disconnected': 'Disconnected',
    'connecting': 'Connecting...',
    'connection_status': 'Connection Status',
    
    # Wallet Info
    'balance_details': 'Balance Details',
    'total_balance': 'Total Balance',
    'pending_receive': 'Pending Receive',
    'pending_send': 'Pending Send',
    'payment_limits': 'Payment Limits',
    'loading_limits': 'Loading limits...',
    'error_loading_limits': 'Error loading limits',
    'no_limits_loaded': 'No limits loaded',
    'send_range': 'Send Range',
    'receive_range': 'Receive Range',
    'liquid_tip': 'Liquid Tip',
    
    # Bitcoin Places
    'find_bitcoin_places': 'Find Bitcoin places near you',
    'getting_location': 'Getting your location...',
    'no_places_nearby': 'No Bitcoin places found nearby',
    'places_near_you': '%d place%@ to spend bitcoin near you',
    'location_required': 'Location Required',
    'find_bitcoin_places_title': 'Find Bitcoin Places Near You',
    'location_permission_message': 'We use your location to show nearby businesses that accept Bitcoin payments. Your location stays private and is never shared with third parties.',
    'enable_location': 'Enable Location',
    'open_settings': 'Open Settings',
    
    # Fee Comparison
    'lightning_network': 'Lightning Network',
    'credit_card_fee': 'Credit Card (3%)',
    'bank_wire_fee': 'Bank Wire ($25)',
    'recommended': 'RECOMMENDED',
    
    # Error Messages
    'insufficient_funds': 'Insufficient funds. You don\'t have enough sats for this payment.',
    'payment_expired': 'This payment request has expired. Please request a new invoice.',
    'invalid_payment': 'Invalid payment request. Please check the QR code or invoice.',
    'network_error': 'Network error. Please check your internet connection and try again.',
    'channel_issue': 'Lightning channel issue. Please try again in a moment.',
    'invalid_invoice': 'Invalid Lightning invoice. Please check the payment request.',
    'invalid_amount': 'Invalid amount',
    'payment_request_expired': 'This payment request has expired',
    
    # Action Buttons
    'try_again': 'Try Again',
    'open_settings_button': 'Open Settings',
    'got_it': 'Got It',
    
    # Loading States
    'loading': 'Loading...',
    'processing': 'Processing...',
    'please_wait_processing': 'Please wait...',
    
    # Default Values
    'lumen_payment': 'Lumen payment',
    'default_description': 'Lightning payment',
    
    # Units
    'sats': 'sats',
    'bitcoin': 'Bitcoin',
    'words': 'words',
    'word': 'word',
    
    # Time
    'now': 'now',
    'minutes_ago': '%d minutes ago',
    'hours_ago': '%d hours ago',
    'days_ago': '%d days ago',
    
    # Import Seed
    'enter_recovery_phrase': 'Enter your %d-word recovery phrase',
    'word_count': 'Word Count:',
    'select_word_count': 'Select Word Count',
    'word_count_question': 'How many words does your seed phrase have?',
    'paste_seed_phrase': 'Paste Seed Phrase',
    'paste_confirmation': 'Found %d words in clipboard. Paste them into the form?',
    'import_wallet_button': 'Import Wallet',
    'importing_wallet': 'Importing Wallet...',
    
    # Pluralization
    'place_singular': '',
    'place_plural': 's',
}

def update_file(filepath):
    """Update L() calls in a single file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Replace L() calls with old keys to new keys
        for old_key, new_key in key_mappings.items():
            # Escape special characters for regex
            escaped_new_key = new_key.replace('"', '\\"').replace("'", "\\'")
            
            # Pattern to match L("old_key") or L('old_key')
            pattern1 = f'L\\("{old_key}"\\)'
            pattern2 = f"L\\('{old_key}'\\)"
            
            replacement = f'L("{escaped_new_key}")'
            
            content = re.sub(pattern1, replacement, content)
            content = re.sub(pattern2, replacement, content)
        
        # Only write if content changed
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated: {filepath}")
        
    except Exception as e:
        print(f"Error updating {filepath}: {e}")

def main():
    """Update all Swift files in the Lumen directory"""
    lumen_dir = "Lumen"
    
    for root, dirs, files in os.walk(lumen_dir):
        for file in files:
            if file.endswith('.swift'):
                filepath = os.path.join(root, file)
                update_file(filepath)

if __name__ == "__main__":
    main()
