import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../services/payment/razorpay_service.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_button.dart';

/// Payment screen for appointment booking
class PaymentScreen extends ConsumerStatefulWidget {
  final AppointmentModel appointment;
  final DoctorModel doctor;
  final UserModel patient;
  final Function(String paymentId) onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.appointment,
    required this.doctor,
    required this.patient,
    required this.onPaymentSuccess,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;
  String? _selectedPaymentMethod;
  Timer? _paymentTimeoutTimer;

  @override
  void initState() {
    super.initState();
    RazorpayService.initialize();
    
    // Add a timeout to reset loading state if payment gets stuck
    _paymentTimeoutTimer = Timer(const Duration(seconds: 45), () {
      if (_isProcessing && mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog('Payment timeout. Please try again or contact support if payment was deducted.');
      }
    });
  }

  @override
  void dispose() {
    _paymentTimeoutTimer?.cancel();
    RazorpayService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consultationFee = widget.appointment.consultationFee ?? 250.0; // Default fee
    final platformFee = consultationFee * 0.02; // 2% platform fee
    final gst = (consultationFee + platformFee) * 0.18; // 18% GST
    final totalAmount = consultationFee + platformFee + gst;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appointment Details
                  _buildAppointmentDetails(),
                  const SizedBox(height: 24),

                  // Payment Summary
                  _buildPaymentSummary(consultationFee, platformFee, gst, totalAmount),
                  const SizedBox(height: 24),

                  // Payment Methods
                  _buildPaymentMethods(),
                  const SizedBox(height: 24),

                  // Terms and Conditions
                  _buildTermsAndConditions(),
                ],
              ),
            ),
          ),

          // Pay Now Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeUtils.getSurfaceColor(context),
              boxShadow: [
                BoxShadow(
                  color: ThemeUtils.getShadowLightColor(context),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      RazorpayService.formatAmount(totalAmount),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeUtils.getPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: _isProcessing ? 'Processing...' : 'Pay Now',
                    onPressed: _isProcessing ? null : _processPayment,
                    isLoading: _isProcessing,
                  ),
                ),
                if (_isProcessing) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Processing your payment...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This will complete within 5 seconds',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointment Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: widget.doctor.profileImageUrl != null
                    ? NetworkImage(widget.doctor.profileImageUrl!)
                    : null,
                child: widget.doctor.profileImageUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${widget.doctor.fullName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.doctor.specialty ?? 'General Medicine',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.ratingFilled,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.doctor.rating?.toStringAsFixed(1) ?? 'N/A'} (${widget.doctor.totalReviews ?? 0} reviews)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Consultation Type', widget.appointment.consultationType.toUpperCase()),
          _buildDetailRow('Date & Time', widget.appointment.formattedDateTime),
          if (widget.appointment.symptoms?.isNotEmpty == true)
            _buildDetailRow('Symptoms', widget.appointment.symptoms!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(double consultationFee, double platformFee, double gst, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Consultation Fee', consultationFee),
          _buildSummaryRow('Platform Fee (2%)', platformFee),
          _buildSummaryRow('GST (18%)', gst),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total Amount',
            totalAmount,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? ThemeUtils.getTextPrimaryColor(context) : ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
          Text(
            RazorpayService.formatAmount(amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? ThemeUtils.getPrimaryColor(context) : ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final paymentMethods = RazorpayService.getSupportedPaymentMethods();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Methods',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...paymentMethods.map((method) => _buildPaymentMethodTile(method)),
          
          // Show payment method specific options when selected
          if (_selectedPaymentMethod != null) ...[
            const SizedBox(height: 16),
            _buildPaymentMethodOptions(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method['id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? ThemeUtils.getPrimaryColorWithOpacity(context, 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? ThemeUtils.getPrimaryColor(context)
                : ThemeUtils.getBorderLightColor(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getPaymentMethodIcon(method['icon']),
              color: isSelected
                  ? ThemeUtils.getPrimaryColor(context)
                  : ThemeUtils.getTextSecondaryColor(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['name'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? ThemeUtils.getPrimaryColor(context)
                          : ThemeUtils.getTextPrimaryColor(context),
                    ),
                  ),
                  Text(
                    method['description'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ThemeUtils.getPrimaryColor(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOptions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ThemeUtils.getPrimaryColor(context).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: ThemeUtils.getPrimaryColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                _getPaymentMethodTitle(_selectedPaymentMethod!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ThemeUtils.getPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getPaymentMethodDetails(_selectedPaymentMethod!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          _buildPaymentMethodSpecificOptions(_selectedPaymentMethod!),
        ],
      ),
    );
  }

  String _getPaymentMethodTitle(String methodId) {
    switch (methodId) {
      case 'card':
        return 'Credit/Debit Card Payment';
      case 'netbanking':
        return 'Net Banking';
      case 'upi':
        return 'UPI Payment';
      case 'wallet':
        return 'Digital Wallet';
      case 'emi':
        return 'EMI Payment';
      default:
        return 'Payment Options';
    }
  }

  String _getPaymentMethodDetails(String methodId) {
    switch (methodId) {
      case 'card':
        return 'Secure payment with your credit or debit card. All major cards accepted.';
      case 'netbanking':
        return 'Pay directly from your bank account. All major banks supported.';
      case 'upi':
        return 'Quick and secure UPI payment. Use any UPI app like Google Pay, PhonePe, etc.';
      case 'wallet':
        return 'Pay using your digital wallet balance. Instant payment confirmation.';
      case 'emi':
        return 'Convert your payment into easy monthly installments. No cost EMI available.';
      default:
        return 'Choose your preferred payment method for secure transaction.';
    }
  }

  Widget _buildPaymentMethodSpecificOptions(String methodId) {
    switch (methodId) {
      case 'card':
        return Column(
          children: [
            Row(
              children: [
                Icon(Icons.security, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text('256-bit SSL encryption', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.verified, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text('PCI DSS compliant', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        );
      case 'upi':
        return Column(
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text('Instant payment confirmation', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone_android, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text('Use any UPI app on your phone', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        );
      case 'netbanking':
        return Row(
          children: [
            Icon(Icons.account_balance, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Text('Direct bank transfer - highly secure', style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      case 'wallet':
        return Row(
          children: [
            Icon(Icons.account_balance_wallet, size: 16, color: Colors.purple),
            const SizedBox(width: 4),
            Text('Use wallet balance for instant payment', style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      case 'emi':
        return Column(
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text('3, 6, 9, 12 months EMI available', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.percent, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text('No cost EMI on select cards', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
  IconData _getPaymentMethodIcon(String iconName) {
    switch (iconName) {
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance':
        return Icons.account_balance;
      case 'qr_code':
        return Icons.qr_code;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Important Information',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Payment is secure and processed by Razorpay\n'
            '• Refunds will be processed within 5-7 business days\n'
            '• Cancellation charges may apply as per policy\n'
            '• By proceeding, you agree to our Terms & Conditions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    // Validate payment method selection
    if (_selectedPaymentMethod == null) {
      _showErrorDialog('Please select a payment method to continue.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print('=== PROCESSING PAYMENT ===');
      print('Payment Method: $_selectedPaymentMethod');
      print('Doctor: ${widget.doctor.fullName}');
      print('Patient: ${widget.patient.fullName}');
      print('Fee: ₹${widget.appointment.consultationFee}');

      // Simulate payment processing with 5-second maximum
      await Future.any([
        _simulatePaymentProcess(),
        Future.delayed(const Duration(seconds: 5)).then((_) {
          throw Exception('Payment timeout after 5 seconds');
        }),
      ]);

    } catch (e) {
      print('Payment processing error: $e');
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Payment failed: ${e.toString()}');
    }
  }

  Future<void> _simulatePaymentProcess() async {
    // Simulate payment processing time (2-4 seconds)
    final processingTime = 2 + (DateTime.now().millisecondsSinceEpoch % 3);
    await Future.delayed(Duration(seconds: processingTime));

    // Generate mock payment ID
    final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    
    print('Payment successful: $paymentId');
    
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      
      // Show success message
      _showPaymentSuccessDialog(paymentId);
    }
  }

  void _showPaymentSuccessDialog(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your payment has been processed successfully.'),
            const SizedBox(height: 8),
            Text(
              'Payment ID: $paymentId',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your appointment is confirmed and the doctor has been notified.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              widget.onPaymentSuccess(paymentId);
              Navigator.pop(context, paymentId); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: ThemeUtils.getErrorColor(context),
            ),
            const SizedBox(width: 8),
            const Text('Payment Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Text(
              'If the problem persists, please contact support.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: value == 'true' ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}