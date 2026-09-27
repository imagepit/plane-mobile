import 'package:get_it/get_it.dart';
import 'package:plane_mobile/core/network/dio_client.dart';
import 'package:plane_mobile/core/storage/credential_store.dart';
import 'package:plane_mobile/core/storage/local_storage.dart';
import 'package:plane_mobile/data/datasources/work_item_remote_datasource.dart';
import 'package:plane_mobile/data/datasources/workspace_remote_datasource.dart';
import 'package:plane_mobile/data/datasources/project_remote_datasource.dart';
import 'package:plane_mobile/data/datasources/state_remote_datasource.dart';
import 'package:plane_mobile/data/datasources/label_remote_datasource.dart';
import 'package:plane_mobile/data/datasources/member_remote_datasource.dart';
import 'package:plane_mobile/data/datasources/comment_remote_datasource.dart';
import 'package:plane_mobile/data/repositories/work_item_repository_impl.dart';
import 'package:plane_mobile/data/repositories/workspace_repository_impl.dart';
import 'package:plane_mobile/data/repositories/project_repository_impl.dart';
import 'package:plane_mobile/domain/repositories/work_item_repository.dart';
import 'package:plane_mobile/domain/repositories/workspace_repository.dart';
import 'package:plane_mobile/domain/repositories/project_repository.dart';
import 'package:plane_mobile/domain/usecases/get_workspaces.dart';
import 'package:plane_mobile/domain/usecases/get_projects.dart';
import 'package:plane_mobile/domain/usecases/get_work_items.dart';
import 'package:plane_mobile/domain/usecases/get_work_item.dart';
import 'package:plane_mobile/domain/usecases/create_work_item.dart';
import 'package:plane_mobile/domain/usecases/update_work_item.dart';
import 'package:plane_mobile/domain/usecases/delete_work_item.dart';
import 'package:plane_mobile/domain/usecases/get_states.dart';
import 'package:plane_mobile/domain/usecases/get_labels.dart';
import 'package:plane_mobile/domain/usecases/get_members.dart';
import 'package:plane_mobile/domain/usecases/get_comments.dart';
import 'package:plane_mobile/domain/usecases/add_comment.dart';
import 'package:plane_mobile/presentation/blocs/settings/settings_bloc.dart';
import 'package:plane_mobile/presentation/blocs/workspace/workspace_bloc.dart';
import 'package:plane_mobile/presentation/blocs/project/project_bloc.dart';
import 'package:plane_mobile/presentation/blocs/work_item/work_item_bloc.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl.registerSingleton<DioClient>(DioClient());

  // 機密（API token）の保存先。LocalStorage より先に初期化し、
  // 完了後に isConfigured を見る順序を保つ。
  final credentialStore = CredentialStore();
  await credentialStore.init();
  sl.registerSingleton<CredentialStore>(credentialStore);

  final localStorage = LocalStorage(credentialStore: credentialStore);
  await localStorage.init();
  sl.registerSingleton<LocalStorage>(localStorage);

  if (localStorage.isConfigured) {
    sl<DioClient>().updateConfig(
      baseUrl: localStorage.selfHostedUrl!,
      apiToken: localStorage.apiToken!,
    );
  }

  sl.registerFactory<WorkItemRemoteDataSource>(
    () => WorkItemRemoteDataSource(sl<DioClient>()),
  );
  sl.registerFactory<WorkspaceRemoteDataSource>(
    () => WorkspaceRemoteDataSource(sl<DioClient>()),
  );
  sl.registerFactory<ProjectRemoteDataSource>(
    () => ProjectRemoteDataSource(sl<DioClient>()),
  );
  sl.registerFactory<StateRemoteDataSource>(
    () => StateRemoteDataSource(sl<DioClient>()),
  );
  sl.registerFactory<LabelRemoteDataSource>(
    () => LabelRemoteDataSource(sl<DioClient>()),
  );
  sl.registerFactory<MemberRemoteDataSource>(
    () => MemberRemoteDataSource(sl<DioClient>()),
  );
  sl.registerFactory<CommentRemoteDataSource>(
    () => CommentRemoteDataSource(sl<DioClient>()),
  );

  sl.registerFactory<WorkItemRepository>(
    () => WorkItemRepositoryImpl(
      sl<WorkItemRemoteDataSource>(),
      sl<StateRemoteDataSource>(),
      sl<LabelRemoteDataSource>(),
      sl<MemberRemoteDataSource>(),
      sl<CommentRemoteDataSource>(),
    ),
  );
  sl.registerFactory<WorkspaceRepository>(
    () => WorkspaceRepositoryImpl(sl<WorkspaceRemoteDataSource>()),
  );
  sl.registerFactory<ProjectRepository>(
    () => ProjectRepositoryImpl(sl<ProjectRemoteDataSource>()),
  );

  sl.registerFactory<GetWorkspaces>(() => GetWorkspaces(sl<WorkspaceRepository>()));
  sl.registerFactory<GetProjects>(() => GetProjects(sl<ProjectRepository>()));
  sl.registerFactory<GetWorkItems>(() => GetWorkItems(sl<WorkItemRepository>()));
  sl.registerFactory<GetWorkItem>(() => GetWorkItem(sl<WorkItemRepository>()));
  sl.registerFactory<CreateWorkItem>(() => CreateWorkItem(sl<WorkItemRepository>()));
  sl.registerFactory<UpdateWorkItem>(() => UpdateWorkItem(sl<WorkItemRepository>()));
  sl.registerFactory<DeleteWorkItem>(() => DeleteWorkItem(sl<WorkItemRepository>()));
  sl.registerFactory<GetStates>(() => GetStates(sl<WorkItemRepository>()));
  sl.registerFactory<GetLabels>(() => GetLabels(sl<WorkItemRepository>()));
  sl.registerFactory<GetMembers>(() => GetMembers(sl<WorkItemRepository>()));
  sl.registerFactory<GetComments>(() => GetComments(sl<WorkItemRepository>()));
  sl.registerFactory<AddComment>(() => AddComment(sl<WorkItemRepository>()));

  sl.registerFactory<SettingsBloc>(
    () => SettingsBloc(localStorage: sl<LocalStorage>(), dioClient: sl<DioClient>()),
  );
  sl.registerFactory<WorkspaceBloc>(
    () => WorkspaceBloc(getWorkspaces: sl<GetWorkspaces>()),
  );
  sl.registerFactory<ProjectBloc>(
    () => ProjectBloc(getProjects: sl<GetProjects>()),
  );
  sl.registerFactory<WorkItemBloc>(
    () => WorkItemBloc(
      getWorkItems: sl<GetWorkItems>(),
      getWorkItem: sl<GetWorkItem>(),
      createWorkItem: sl<CreateWorkItem>(),
      updateWorkItem: sl<UpdateWorkItem>(),
      deleteWorkItem: sl<DeleteWorkItem>(),
      getStates: sl<GetStates>(),
      getLabels: sl<GetLabels>(),
      getMembers: sl<GetMembers>(),
      getComments: sl<GetComments>(),
      addComment: sl<AddComment>(),
    ),
  );
}