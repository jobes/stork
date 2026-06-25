import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/repositories/black_box_repository.dart';
import '../../data/repositories/black_box_repository_impl.dart';
import '../../../../core/services/database/black_box_database.dart';

part 'black_box_repository_provider.g.dart';

@Riverpod(keepAlive: true)
BlackBoxDatabase blackBoxDatabase(Ref ref) {
  return BlackBoxDatabase();
}

@Riverpod(keepAlive: true)
BlackBoxRepository blackBoxRepository(Ref ref) {
  return BlackBoxRepositoryImpl(ref.watch(blackBoxDatabaseProvider));
}
