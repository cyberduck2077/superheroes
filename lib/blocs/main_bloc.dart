import 'dart:async';

import 'package:rxdart/rxdart.dart';

class MainBloc {
  static const minSymbols = 3;

  final BehaviorSubject<MainPageState> stateSubjects = BehaviorSubject();
  final favoritesSuperheroesSubjects =
      BehaviorSubject<List<SuperheroInfo>>.seeded(SuperheroInfo.mocked);
  final searchSuperheroesSubjects = BehaviorSubject<List<SuperheroInfo>>();
  final currentTextSubject = BehaviorSubject<String>.seeded("");

  StreamSubscription? textSubscription;
  StreamSubscription? searchSubscription;

  MainBloc() {
    stateSubjects.add(MainPageState.noFavorites);

    /*Комбинируем 2 стрима:
    * 1 стрим - вводимый текст (currentTextSubject)
    * 2 стрим - информация о текущих добавленных избранных супергероях (favoritesSuperheroesSubjects)
    * Упаковываем получаемые со стримов объекты в класс MainPageStateInfo*/
    textSubscription =
        Rx.combineLatest2<String, List<SuperheroInfo>, MainPageStateInfo>(
      currentTextSubject.distinct().debounceTime(Duration(milliseconds: 500)),
      favoritesSuperheroesSubjects,
      (searchedText, favorites) =>
          MainPageStateInfo(searchedText, favorites.isNotEmpty),
    ).listen((value) {
      //distinct() - заходим в условие только когда изменяется текст! debounceTime - задержка 0.5с. перед началом поиска
      print("CHANGED $value");
      searchSubscription?.cancel(); //отменяем предыдущий запрос на поиск
      if (value.searchText.isEmpty) {
        if (value.haveFavorites) {
          stateSubjects.add(MainPageState.favorites);
        } else {
          stateSubjects.add(MainPageState.noFavorites);
        }
      } else if (value.searchText.length < minSymbols) {
        stateSubjects.add(MainPageState.minSymbols);
      } else {
        searchForSuperheroes(value.searchText);
      }
    });
  }

  void searchForSuperheroes(final String text) {
    stateSubjects.add(
        MainPageState.loading); //пока идет поиск, проиходит вращение спинера
    searchSubscription = search(text).asStream().listen((searchResults) {
      if (searchResults.isEmpty) {
        stateSubjects.add(MainPageState.nothingFound);
      } else {
        searchSuperheroesSubjects.add(searchResults);
        stateSubjects.add(MainPageState.searchResult);
      }
    }, onError: (error, stackTrace) {
      stateSubjects.add(MainPageState.loadingError);
    });
  }

  Stream<List<SuperheroInfo>> observeFavoriteSuperheroes() =>
      favoritesSuperheroesSubjects;

  Stream<List<SuperheroInfo>> observeSearchSuperheroes() =>
      searchSuperheroesSubjects;

  Future<List<SuperheroInfo>> search(final String text) async {
    await Future.delayed(Duration(seconds: 1));

    /*фильтрация данных в списке - where*/
    return SuperheroInfo.mocked
        .where((superheroInfo) =>
            superheroInfo.name.toLowerCase().contains(text.toLowerCase()))
        .toList();
  }

  Stream<MainPageState> observeMainPageState() => stateSubjects;

  void removeFavorite() {
    final List<SuperheroInfo> currentFavorites =
        favoritesSuperheroesSubjects.value;
    if (currentFavorites.isEmpty) {
      favoritesSuperheroesSubjects.add(SuperheroInfo.mocked);
    } else {
      favoritesSuperheroesSubjects
          .add(currentFavorites.sublist(0, currentFavorites.length - 1));
    }
  }

  /*срабатывет при нажатии onTap()*/
  void nextState() {
    //add new value to stateController
    final currentState = stateSubjects.value;
    final nextState = MainPageState.values[
        (MainPageState.values.indexOf(currentState) + 1) %
            MainPageState.values.length];
    stateSubjects.sink.add(nextState);
  }

  void updateText(final String? text) {
    currentTextSubject.add(text ?? ""); //(text!=null ? text : "")
  }

  void dispose() {
    stateSubjects.close();
    favoritesSuperheroesSubjects.close();
    searchSuperheroesSubjects.close();
    currentTextSubject.close();

    textSubscription?.cancel();
  }
}

enum MainPageState {
  noFavorites,
  minSymbols,
  loading,
  nothingFound,
  loadingError,
  searchResult,
  favorites,
}

class SuperheroInfo {
  final String name;
  final String realName;
  final String imageUrl;

  const SuperheroInfo({
    required this.name,
    required this.realName,
    required this.imageUrl,
  });

  @override
  String toString() {
    return 'SuperheroInfo{name: $name, realName: $realName, imageUrl: $imageUrl}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuperheroInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          realName == other.realName &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => name.hashCode ^ realName.hashCode ^ imageUrl.hashCode;

  static const mocked = [
    SuperheroInfo(
      name: "Batman",
      realName: "Bruce Wayne",
      imageUrl:
          "https://www.superherodb.com/pictures2/portraits/10/100/639.jpg",
    ),
    SuperheroInfo(
      name: "Ironman",
      realName: "Tony Stark",
      imageUrl: "https://www.superherodb.com/pictures2/portraits/10/100/85.jpg",
    ),
    SuperheroInfo(
      name: "Venom",
      realName: "Eddie Brock",
      imageUrl: "https://www.superherodb.com/pictures2/portraits/10/100/22.jpg",
    ),
  ];
}

class MainPageStateInfo {
  final String searchText;
  final bool haveFavorites;

  const MainPageStateInfo(this.searchText, this.haveFavorites);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MainPageStateInfo &&
          runtimeType == other.runtimeType &&
          searchText == other.searchText &&
          haveFavorites == other.haveFavorites;

  @override
  int get hashCode => searchText.hashCode ^ haveFavorites.hashCode;

  @override
  String toString() {
    return 'MainPageStateInfo{searchText: $searchText, haveFavorites: $haveFavorites}';
  }
}
