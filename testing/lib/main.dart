import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(CurrencyConverterApp());

class CurrencyConverterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CurrencyConverterScreen(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
    );
  }
}

class CurrencyConverterScreen extends StatefulWidget {
  @override
  _CurrencyConverterScreenState createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _countrySearchController =
      TextEditingController();

  List<String> _currencies = [];
  String? _sourceCurrency;
  String? _targetCurrency;
  String _result = '';
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _conversionHistory = [];
  String? _userName;
  List<String> _filteredCurrencies = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrencies();
  }

  Future<void> _fetchCurrencies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currencies = (data['rates'] as Map<String, dynamic>).keys.toList();
          _filteredCurrencies = List.from(_currencies);
          _sourceCurrency = _currencies[0];
          _targetCurrency = _currencies[1];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch currencies.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: Unable to fetch currencies.';
        _isLoading = false;
      });
    }
  }

  void _filterCurrencies(String input) {
    setState(() {
      _filteredCurrencies = _currencies
          .where((currency) =>
              currency.toLowerCase().contains(input.toLowerCase()))
          .toList();
    });
  }

  Future<void> _convertCurrency() async {
    if (_sourceCurrency == null || _targetCurrency == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final double amount = double.parse(_amountController.text);

      final response = await http.get(
        Uri.parse(
            'https://api.exchangerate-api.com/v4/latest/$_sourceCurrency'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rate = data['rates'][_targetCurrency];
        final convertedAmount = amount * rate;

        setState(() {
          _result =
              '$amount $_sourceCurrency = ${convertedAmount.toStringAsFixed(2)} $_targetCurrency';
          _conversionHistory.add('$_userName: $_result');
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch exchange rate.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid input or network error.';
        _isLoading = false;
      });
    }
  }

  void _submitName() {
    if (_nameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Name is required.';
      });
      return;
    }
    setState(() {
      _userName = _nameController.text;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Converter'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading && _currencies.isEmpty
            ? Center(child: CircularProgressIndicator())
            : _userName == null
                ? Column(
                    children: [
                      Text(
                        'Welcome!',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Enter Your Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitName,
                        child: Text('Submit'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Hello, $_userName!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Enter Amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: _sourceCurrency,
                              isExpanded: true,
                              items: _filteredCurrencies.map((currency) {
                                return DropdownMenuItem<String>(
                                  value: currency,
                                  child: Text(currency),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _sourceCurrency = value!;
                                });
                              },
                              hint: Text('Source Currency'),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _targetCurrency,
                              isExpanded: true,
                              items: _filteredCurrencies.map((currency) {
                                return DropdownMenuItem<String>(
                                  value: currency,
                                  child: Text(currency),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _targetCurrency = value!;
                                });
                              },
                              hint: Text('Target Currency'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _convertCurrency,
                        child: Text('Convert'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      if (_result.isNotEmpty)
                        Text(
                          _result,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      Divider(),
                      Text(
                        'Conversion History:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _conversionHistory.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(_conversionHistory[index]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
