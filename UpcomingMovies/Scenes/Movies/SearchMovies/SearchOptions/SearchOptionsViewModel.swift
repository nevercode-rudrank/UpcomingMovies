//
//  SearchOptionsViewModel.swift
//  UpcomingMovies
//
//  Created by Alonso on 1/15/19.
//  Copyright © 2019 Alonso. All rights reserved.
//

import Foundation
import UpcomingMoviesDomain

final class SearchOptionsViewModel: SearchOptionsViewModelProtocol {
    
    private var useCaseProvider: UseCaseProviderProtocol
    private var movieVisitUseCase: MovieVisitUseCaseProtocol
    private var genreUseCase: GenreUseCaseProtocol
    
    private var genres: [Genre] = []
    
    let viewState: Bindable<SearchOptionsViewState> = Bindable(.emptyMovieVisits)
    
    var needsContentReload: (() -> Void)?
    var updateVisitedMovies: Bindable<Int?> = Bindable(nil)
    
    var selectedDefaultSearchOption: Bindable<DefaultSearchOption?> = Bindable(nil)
    var selectedMovieGenre: Bindable<(Int?, String?)> = Bindable((nil, nil))
    var selectedRecentlyVisitedMovie: ((Int, String) -> Void)?
    
    var visitedMovieCells: [VisitedMovieCellViewModel] {
        let visited = movieVisitUseCase.getMovieVisits()
        return visited.map { VisitedMovieCellViewModel(movieVisit: $0) }
    }
    
    var genreCells: [GenreSearchOptionCellViewModel] {
        return genres.map { GenreSearchOptionCellViewModel(genre: $0) }
    }
    
    private let defaultSearchOptions: [DefaultSearchOption] = [.popular, .topRated]
    var defaultSearchOptionsCells: [DefaultSearchOptionCellViewModel] {
        return defaultSearchOptions.map { DefaultSearchOptionCellViewModel(defaultSearchOption: $0) }
    }
    
    // MARK: - Initializers
    
    init(useCaseProvider: UseCaseProviderProtocol) {
        self.useCaseProvider = useCaseProvider
        self.genreUseCase = self.useCaseProvider.genreUseCase()
        
        movieVisitUseCase = self.useCaseProvider.movieVisitUseCase()
        movieVisitUseCase.didUpdateMovieVisit = { [weak self] in
            guard let strongSelf = self else { return }
            // If the state changed we reload the entire table view
            let viewStateChanged = strongSelf.configureViewState()
            if viewStateChanged {
                strongSelf.needsContentReload?()
            } else {
                let index = strongSelf.sectionIndex(for: .recentlyVisited)
                strongSelf.updateVisitedMovies.value = index
            }
        }
        
        configureViewState()
    }
    
    // MARK: - Private
    
    /**
     * Configures the state of the view according to the saved movie visits
     * quantity. Returns true if the state changed and false if not.
     */
    @discardableResult
    private func configureViewState() -> Bool {
        let oldViewState = viewState.value
        if movieVisitUseCase.hasMovieVisits() {
            viewState.value = .populatedMovieVisits
        } else {
            viewState.value = .emptyMovieVisits
        }
        return oldViewState != viewState.value
    }
    
    // MARK: - Public
    
    func load() {
        genreUseCase.fetchAll(completion: { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let genres):
                strongSelf.genres = genres
                strongSelf.needsContentReload?()
            case .failure:
                break
            }
        })
    }
    
    func section(at index: Int) -> SearchOptionsSection {
        return viewState.value.sections[index]
    }
    
    func sectionIndex(for section: SearchOptionsSection) -> Int? {
        let sections = viewState.value.sections
        return sections.firstIndex(of: section)
    }
    
    func buildRecentlyVisitedMoviesCell() -> RecentlyVisitedMoviesCellViewModel {
        return RecentlyVisitedMoviesCellViewModel(visitedMovieCells: visitedMovieCells)
    }
    
    func getDefaultSearchSelection(by index: Int) {
        let defaultSearchOption = defaultSearchOptions[index]
        selectedDefaultSearchOption.value = defaultSearchOption
    }
    
    func getMovieGenreSelection(by index: Int) {
        let selectedGenre = genres[index]
        selectedMovieGenre.value = (selectedGenre.id, selectedGenre.name)
    }
    
    func getRecentlyVisitedMovieSelection(by index: Int) {
        let visitedMovies = movieVisitUseCase.getMovieVisits()
        let selectedVisitedMovie = visitedMovies[index]
        selectedRecentlyVisitedMovie?(selectedVisitedMovie.id, selectedVisitedMovie.title)
    }

}
