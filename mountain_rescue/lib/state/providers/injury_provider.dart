import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/injury_model.dart';
import '../../data/repositories/injury_repository.dart';

final injuryRepositoryProvider = Provider((ref) => InjuryRepository());

final rescuerInjuriesProvider = StreamProvider.family<List<Injury>, String>((
  ref,
  rescuerId,
) {
  final repo = ref.watch(injuryRepositoryProvider);
  return repo.getInjuriesByRescuer(rescuerId);
});
