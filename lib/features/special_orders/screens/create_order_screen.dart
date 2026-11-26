import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jantabackery/core/database/db_helper.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flavourController = TextEditingController();
  final _customWeightController = TextEditingController();
  final _messageController = TextEditingController();
  final _totalPriceController = TextEditingController();
  final _advanceController = TextEditingController();

  String _selectedWeight = '1 Kg';
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 1));
  File? _designImage;

  final List<String> _weights = ['1/2 Kg', '1 Kg', '1.5 Kg', '2 Kg', 'Custom'];

  double get _balanceAmount {
    final total = double.tryParse(_totalPriceController.text) ?? 0;
    final advance = double.tryParse(_advanceController.text) ?? 0;
    return (total - advance) < 0 ? 0 : (total - advance);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _designImage = File(picked.path));
    }
  }

  Future<void> _pickDeliveryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deliveryDate),
    );
    if (time == null || !mounted) return;

    setState(() {
      _deliveryDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final finalWeight = _selectedWeight == 'Custom'
        ? _customWeightController.text.trim()
        : _selectedWeight;
    if (finalWeight.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final db = await DBHelper.database;
    await db.insert('special_orders', {
      'customer_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'flavour': _flavourController.text.trim(),
      'weight': finalWeight,
      'message': _messageController.text.trim(),
      'total_price': double.tryParse(_totalPriceController.text) ?? 0,
      'advance_paid': double.tryParse(_advanceController.text) ?? 0,
      'delivery_date': _deliveryDate.toIso8601String(),
      'image_path': _designImage?.path ?? '',
      'status': 'Pending',
    });

    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Special Cake Order Booked!'),
        backgroundColor: Colors.green,
      ),
    );
    navigator.pop(true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _flavourController.dispose();
    _customWeightController.dispose();
    _messageController.dispose();
    _totalPriceController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(_deliveryDate);

    return Scaffold(
      appBar: AppBar(title: const Text('New Special Cake Order')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name *',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter customer name' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number *',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) =>
              v == null || v.trim().length < 10 ? 'Enter valid 10-digit number' : null,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: TextFormField(
                    controller: _flavourController,
                    decoration: const InputDecoration(
                      labelText: 'Flavour *',
                      isDense: true,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter flavour' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedWeight,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      isDense: true,
                    ),
                    items: _weights
                        .map(
                          (w) => DropdownMenuItem<String>(
                        value: w,
                        child: Text(
                          w,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedWeight = val);
                    },
                  ),
                ),
              ],
            ),
            if (_selectedWeight == 'Custom') ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _customWeightController,
                decoration: const InputDecoration(
                  labelText: 'Custom Weight (e.g. 2.5 Kg, 4 Kg) *',
                  isDense: true,
                ),
                validator: (v) =>
                _selectedWeight == 'Custom' && (v == null || v.trim().isEmpty)
                    ? 'Enter custom weight'
                    : null,
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message on Cake',
                prefixIcon: Icon(Icons.cake_outlined),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              tileColor: Colors.white,
              leading: const Icon(Icons.calendar_month_rounded, color: Color(0xFFD81B60)),
              title: const Text('Delivery Date & Time', style: TextStyle(fontSize: 13.5)),
              subtitle: Text(
                formattedDate,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              trailing: const Icon(Icons.edit_outlined, size: 20),
              onTap: _pickDeliveryDate,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 128,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                ),
                child: _designImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _designImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 34, color: Colors.grey.shade500),
                    const SizedBox(height: 6),
                    Text(
                      'Upload Cake Design Reference Photo',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalPriceController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Total Price *',
                      isDense: true,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter price' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _advanceController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Advance Paid',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Remaining Balance:',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _balanceAmount.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD81B60),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD81B60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _saveOrder,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Book Special Order', style: TextStyle(fontSize: 15.5)),
            ),
          ],
        ),
      ),
    );
  }
}