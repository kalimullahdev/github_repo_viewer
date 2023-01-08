import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:github_repo_viewer/main/presentation/toasts.dart';
import 'package:github_repo_viewer/github/core/presentation/no_results_display.dart';
import 'package:github_repo_viewer/github/repos/core/application/paginated_repos_notifier.dart';
import 'package:github_repo_viewer/github/repos/core/presentation/failure_repo_tile.dart';
import 'package:github_repo_viewer/github/repos/core/presentation/loading_repo_tile.dart';
import 'package:github_repo_viewer/github/repos/core/presentation/repo_tile.dart';

class PaginatedReposListView extends StatefulWidget {
  final AutoDisposeStateNotifierProvider<PaginatedReposNotifier, PaginatedReposState> paginatedReposNotifierProvider;
  final void Function(/*WidgetReference ref*/ BuildContext context) getNextPage;
  final String noResultsMessage;

  const PaginatedReposListView({
    super.key,
    required this.paginatedReposNotifierProvider,
    required this.getNextPage,
    required this.noResultsMessage,
  });

  @override
  _PaginatedReposListViewState createState() => _PaginatedReposListViewState();
}

class _PaginatedReposListViewState extends State<PaginatedReposListView> {
  bool canLoadNextPage = false;
  bool hasAlreadyShownNoConnectionToast = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        ref.listen<PaginatedReposState>(
          widget.paginatedReposNotifierProvider,
          (_, state) => state.map(
            initial: (_) => canLoadNextPage = true,
            loadInProgress: (_) => canLoadNextPage = false,
            loadSuccess: (_) {
              if (!_.repos.isFresh && !hasAlreadyShownNoConnectionToast) {
                hasAlreadyShownNoConnectionToast = true;
                showNoConnectionToast(
                  "You're not online. Some information may be outdated.",
                  context,
                );
              }
              canLoadNextPage = _.isNextPageAvailable;
              return null;
            },
            loadFailure: (_) => canLoadNextPage = false,
          ),
        );

        final state = ref.watch(widget.paginatedReposNotifierProvider);
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            final metrics = notification.metrics;
            final limit = metrics.maxScrollExtent - metrics.viewportDimension / 3;

            if (canLoadNextPage && metrics.pixels >= limit) {
              canLoadNextPage = false;
              widget.getNextPage(/*ref*/ context);
            }
            return false;
          },
          child: state.maybeWhen(
            loadSuccess: (repos, _) => repos.entity.isEmpty,
            orElse: () => false,
          )
              ? NoResultsDisplay(
                  message: widget.noResultsMessage,
                )
              : _PaginatedListView(state: state),
        );
      },
    );
  }
}

class _PaginatedListView extends StatelessWidget {
  const _PaginatedListView({
    super.key,
    required this.state,
  });

  final PaginatedReposState state;

  @override
  Widget build(BuildContext context) {
    final fsb = FloatingSearchBar.of(context)?.widget;
    return ListView.builder(
      padding: fsb == null
          ? EdgeInsets.zero
          : EdgeInsets.only(
              top: fsb.height + 8 + MediaQuery.of(context).padding.top,
            ),
      itemCount: state.map(
        initial: (_) => 0,
        loadInProgress: (_) => _.repos.entity.length + _.itemsPerPage,
        loadSuccess: (_) => _.repos.entity.length,
        loadFailure: (_) => _.repos.entity.length + 1,
      ),
      itemBuilder: (contex, index) {
        return state.map(
          initial: (_) => RepoTile(repo: _.repos.entity[index]),
          loadInProgress: (_) {
            if (index < _.repos.entity.length) {
              return RepoTile(repo: _.repos.entity[index]);
            } else {
              return const LoadingRepoTile();
            }
          },
          loadSuccess: (_) => RepoTile(
            repo: _.repos.entity[index],
          ),
          loadFailure: (_) {
            if (index < _.repos.entity.length) {
              return RepoTile(repo: _.repos.entity[index]);
            } else {
              return FailureRepoTile(failure: _.failure);
            }
          },
        );
      },
    );
  }
}
