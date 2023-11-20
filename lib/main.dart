import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_aruzhanros2/bloc/search_bloc.dart';
import 'package:flutter_aruzhanros2/bloc/user_bloc.dart';
import 'package:flutter_aruzhanros2/counter_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:search_user_repository/search_user_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (context) =>
                SearchBloc(searchUserRepository: SearchUserRepository())),
        BlocProvider(create: (context) => CounterBloc()),
        BlocProvider(
            create: (context) =>
                UserBloc(BlocProvider.of<CounterBloc>(context))),
      ],
      child: MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(
            bodyText2: TextStyle(fontSize: 33),
            subtitle1: TextStyle(fontSize: 22),
          ),
        ),
        home: FirstPage(),
      ),
    );
  }
}

class FirstPage extends StatelessWidget {
  const FirstPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Главная страница"),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SearchUserPage()));
            },
          ),
          Icon(Icons.star),
        ],
      ),
      floatingActionButton: BlocConsumer<CounterBloc, int>(
        buildWhen: (prev, current) => prev > current,
        listenWhen: (prev, current) => prev > current,
        listener: (context, state) {
          if (state == 0) {
            Scaffold.of(context).showBottomSheet(
              (context) => Container(
                color: Colors.blue,
                width: double.infinity,
                height: 30,
                child: Text('State is 0'),
              ),
            );
          }
        },
        builder: (context, state) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.toString()),
            IconButton(
              onPressed: () {
                context.read<CounterBloc>().add(CounterIncEvent());
              },
              icon: const Icon(Icons.plus_one),
            ),
            IconButton(
              onPressed: () {
                context.read<CounterBloc>().add(CounterDecEvent());
              },
              icon: const Icon(Icons.exposure_minus_1),
            ),
            IconButton(
              onPressed: () {
                final userBloc = context.read<UserBloc>();
                userBloc
                    .add(UserGetUsersEvent(context.read<CounterBloc>().state));
              },
              icon: const Icon(Icons.person),
            ),
            IconButton(
              onPressed: () {
                final userBloc = context.read<UserBloc>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Job(),
                  ),
                );
                userBloc.add(
                    UserGetUsersJobEvent(context.read<CounterBloc>().state));
              },
              icon: const Icon(Icons.work),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              BlocBuilder<CounterBloc, int>(
                builder: (context, state) {
                  final users =
                      context.select((UserBloc bloc) => bloc.state.users);
                  return Column(
                    children: [
                      Text(state.toString(), style: TextStyle(fontSize: 33)),
                      if (users.isNotEmpty) ...users.map((e) => Text(e.name)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchUserPage extends StatelessWidget {
  const SearchUserPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final users = context.select((SearchBloc bloc) => bloc.state.users);
    return Scaffold(
      appBar: AppBar(
        title: Text("Поиск пользователя"),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          Icon(Icons.search) // Дополнительная иконка
        ],
      ),
      body: Column(
        children: [
          const Text('Search User'),
          const SizedBox(height: 20),
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'User name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              context.read<SearchBloc>().add(SearchUserEvent(value));
            },
          ),
          if (users.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(user.username ?? ''),
                    leading: Hero(
                      tag: user.username ?? '',
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(user.images ?? ''),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserInfoScreen(
                            user: user,
                          ),
                        ),
                      );
                    },
                  );
                },
                itemCount: users.length,
              ),
            ),
        ],
      ),
    );
  }
}

class UserInfoScreen extends StatelessWidget {
  const UserInfoScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          user.username ?? '',
          style: const TextStyle(fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          Hero(
            tag: user.username ?? '',
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(user.images ?? ''),
                ),
              ),
            ),
          ),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 16),
              children: [
                const TextSpan(text: 'Visit Site: '),
                TextSpan(
                    text: user.url ?? '',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Job extends StatelessWidget {
  const Job({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          final job = state.job;
          return Column(
            children: [
              if (state.isLoading) const CircularProgressIndicator(),
              if (job.isNotEmpty) ...job.map((e) => Text(e.name)),
            ],
          );
        },
      ),
    );
  }
}
