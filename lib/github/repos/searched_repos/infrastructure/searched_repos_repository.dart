import 'package:dartz/dartz.dart';
import 'package:github_repo_viewer/github/core/domain/github_failure.dart';
import 'package:github_repo_viewer/github/core/domain/github_repo.dart';
import 'package:github_repo_viewer/github/repos/core/infrastructure/extensions.dart';
import 'package:github_repo_viewer/github/repos/searched_repos/infrastructure/searched_repos_remote_service.dart';
import 'package:github_repo_viewer/main/domain/fresh.dart';
import 'package:github_repo_viewer/main/infrastructure/network_exceptions.dart';

class SearchedReposRepository {
  final SearchedReposRemoteService _remoteService;

  SearchedReposRepository(this._remoteService);

  Future<Either<GithubFailure, Fresh<List<GithubRepo>>>> getSearchedReposPage(
    String query,
    int page,
  ) async {
    try {
      final remotePageItems = await _remoteService.getSearchedReposPage(query, page);
      return right(
        remotePageItems.maybeWhen(
          withNewData: (data, maxPage) => Fresh.yes(
            data.toDomain(),
            isNextPageAvailable: page < maxPage,
          ),
          orElse: () => Fresh.no([], isNextPageAvailable: false),
        ),
      );
    } on RestApiException catch (e) {
      return left(GithubFailure.api(e.errorCode));
    }
  }
}
