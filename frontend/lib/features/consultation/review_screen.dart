import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'consultation_controller.dart';

/// Pantalla de revisión: el médico edita y valida el borrador generado por IA.
/// El control humano es obligatorio: nada se guarda en el HIS sin validar aquí.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(consultationProvider);
    final note = state.note;

    if (note == null) {
      return const Scaffold(body: Center(child: Text('Sin borrador todavía')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Revisión de la historia clínica')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Motivo de consulta', note.motivoConsulta.content),
          _section('Anamnesis', note.anamnesis.content),
          _section('Exploración', note.exploracion.content),
          _section('Diagnóstico', note.diagnostico.content),
          _section('Plan', note.plan.content),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => ref.read(consultationProvider.notifier).validate('demo-patient'),
            child: const Text('Validar y guardar en el historial'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String content) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: content,
              maxLines: null,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
      );
}
