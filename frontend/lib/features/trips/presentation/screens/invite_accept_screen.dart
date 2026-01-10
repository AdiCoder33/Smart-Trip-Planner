import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/invite_accept_cubit.dart';

class InviteAcceptScreen extends StatefulWidget {
  const InviteAcceptScreen({super.key});

  @override
  State<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends State<InviteAcceptScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InviteAcceptCubit, InviteAcceptState>(
      listener: (context, state) {
        if (state.status == InviteAcceptStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite accepted. You can access the trip now.')),
          );
          Navigator.of(context).pop();
        }
        if (state.status == InviteAcceptStatus.error && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Accept Invite')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paste the invite token you received via email.'),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(labelText: 'Invite token'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.status == InviteAcceptStatus.loading ? null : _submit,
                    child: Text(
                      state.status == InviteAcceptStatus.loading ? 'Submitting...' : 'Accept Invite',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    final token = _controller.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is required.')),
      );
      return;
    }
    context.read<InviteAcceptCubit>().submit(token);
  }
}
