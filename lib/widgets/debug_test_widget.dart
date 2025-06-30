// lib/widgets/debug_test_widget.dart - CORRECTED VERSION
// Add this temporarily to your autopsy list screen to test connectivity

import 'package:fieldx_fsm/models/autopsy_models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/autopsy_service.dart';
import '../repositories/autopsy_repository.dart';

class DebugTestWidget extends StatefulWidget {
  const DebugTestWidget({super.key});

  @override
  State<DebugTestWidget> createState() => _DebugTestWidgetState();
}

class _DebugTestWidgetState extends State<DebugTestWidget> {
  String _testResults = 'Ready to test...';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEBUG TESTS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 16),
            
            // Test Results
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _testResults,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Test Buttons
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _testBackendConnectivity,
                          child: Text('Test Backend'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _testParameters,
                          child: Text('Test Params'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _testAutopsyService,
                          child: Text('Test Service'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _testRepository,
                          child: Text('Test Repository'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _testFallback,
                    child: Text('Test Fallback'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testParameters() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing different parameter combinations...';
    });

    try {
      final autopsyService = context.read<AutopsyService>();
      final results = await autopsyService.testParameterCombinations();
      
      final successfulTests = results.entries.where((e) => e.value['status'] == 'success').toList();
      final failedTests = results.entries.where((e) => e.value['status'] == 'failed').toList();
      
      setState(() {
        _testResults = '''
PARAMETER COMBINATION TEST:

SUCCESSFUL TESTS (${successfulTests.length}):
${successfulTests.map((e) => '✅ ${e.key}: ${e.value['dataCount']} records').join('\n')}

FAILED TESTS (${failedTests.length}):
${failedTests.map((e) => '❌ ${e.key}: ${e.value['error']?.split('\n').first ?? 'Unknown error'}').join('\n')}

${successfulTests.isNotEmpty ? '✅ Use parameters from successful tests!' : '❌ All tests failed - check backend API documentation'}

Check console for detailed logs!
        ''';
      });
    } catch (e) {
      setState(() {
        _testResults = '''
PARAMETER TEST FAILED:
Error: $e

Check console for detailed logs!
        ''';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testBackendConnectivity() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing backend connectivity...';
    });

    try {
      final autopsyService = context.read<AutopsyService>();
      final result = await autopsyService.testBackendConnectivity();
      
      setState(() {
        _testResults = '''
BACKEND CONNECTIVITY TEST:
Status: ${result['status']}
API URL: ${result['apiUrl'] ?? 'N/A'}
Endpoint Test: ${result['endpointTest'] ?? 'N/A'}
Response Status: ${result['responseStatus'] ?? 'N/A'}
Error: ${result['error'] ?? result['endpointError'] ?? 'None'}
Time: ${result['timestamp']}

Check console for detailed logs!
        ''';
      });
    } catch (e) {
      setState(() {
        _testResults = '''
BACKEND TEST FAILED:
Error: $e

Check console for detailed logs!
        ''';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testAutopsyService() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing AutopsyService directly...';
    });

    try {
      final autopsyService = context.read<AutopsyService>();
      final params = ListAutopsyParams(limit: 5);
      final result = await autopsyService.listAutopsies(params);
      
      setState(() {
        _testResults = '''
AUTOPSY SERVICE TEST:
✅ SUCCESS!
Total: ${result.total}
Returned: ${result.data.length}
Limit: ${result.limit}
Offset: ${result.offset}

First autopsy:
${result.data.isNotEmpty ? result.data.first.name ?? 'No name' : 'None'}

Check console for detailed logs!
        ''';
      });
    } catch (e) {
      setState(() {
        _testResults = '''
AUTOPSY SERVICE TEST:
❌ FAILED!
Error: $e

Check console for detailed logs!
        ''';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testRepository() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing AutopsyRepository...';
    });

    try {
      final repository = context.read<AutopsyRepository>();
      
      // Clear any existing data
      await repository.clearCaches();
      
      // Try to load autopsies
      await repository.loadAutopsies(refresh: true);
      
      setState(() {
        _testResults = '''
AUTOPSY REPOSITORY TEST:
${repository.error != null ? '❌ FAILED!' : '✅ SUCCESS!'}
Error: ${repository.error ?? 'None'}
Loading: ${repository.isLoading}
Total Count: ${repository.totalCount}
Autopsies: ${repository.autopsies.length}
Has More: ${repository.hasMore}

Check console for detailed logs!
        ''';
      });
    } catch (e) {
      setState(() {
        _testResults = '''
AUTOPSY REPOSITORY TEST:
❌ FAILED!
Error: $e

Check console for detailed logs!
        ''';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testFallback() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing fallback data...';
    });

    try {
      final autopsyService = context.read<AutopsyService>();
      final result = await autopsyService.createTestAutopsyList();
      
      setState(() {
        _testResults = '''
FALLBACK TEST:
✅ SUCCESS!
Total: ${result.total}
Data: ${result.data.length}
Test Autopsy: ${result.data.first.name}

This confirms the app logic works!
The issue is with backend connectivity.

Check console for detailed logs!
        ''';
      });
    } catch (e) {
      setState(() {
        _testResults = '''
FALLBACK TEST:
❌ FAILED!
Error: $e

This suggests an app logic issue.

Check console for detailed logs!
        ''';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}