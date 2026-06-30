import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gwent_repository.dart';

final gwentRepositoryProvider = Provider<GwentRepository>((ref) => GwentRepository());
