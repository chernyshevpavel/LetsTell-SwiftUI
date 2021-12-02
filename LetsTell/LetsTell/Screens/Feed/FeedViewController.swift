//
//  FeedViewController.swift
//  LetsTell
//
//  Created by Павел Чернышев on 02.04.2021.
//  Copyright (c) 2021 ___ORGANIZATIONNAME___. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import Foundation
import Combine

protocol FeedDisplayLogic: class {
    func displayFeed(viewModel: Feed.Network.ViewModel)
    func displayFeed(error: String)
    func displayRefreshedFeed(viewModel: Feed.Network.ViewModel)
    func displayStoryImage(viewModel: Feed.StoryImage.ViewModel)
}

class FeedViewController: ObservableObject, FeedDisplayLogic {
 
    var interactor: FeedBusinessLogic?
    @Published var stories: [Story] = []
    @Published var error: String = ""
    @Published fileprivate(set) var currentlyLoading = false
    @Published fileprivate(set) var currentlyFiltersApplying = false
    @Published  var currentlyRefreshing = false
    
    fileprivate var isSetup = false
    fileprivate var currentPage = 1
    fileprivate var hasMoreStories = true
    
    var scrollToTop: (() -> Void)?
    
    public func setup(container: ObjectsGetter) {
        if !isSetup {
            let viewController = self
            let interactor = FeedInteractor(
                requestFactory: container.getObject(),
                storeToken: container.getObject(),
                authController: container.getObject(),
                applyedFiltersStorage: container.getObject(),
                ownerStorage: container.getObject())
            interactor.errorLogger = container.getObject()
            let presenter = FeedPresenter()
            
            viewController.interactor = interactor
            interactor.presenter = presenter
            presenter.viewController = viewController
            
            loadFeed()
            isSetup = true
        }
    }
    
    func onStoryAppear(story: Story) {
        if shouldLoadMoreStories(story: story) {
            loadFeed(page: currentPage + 1)
        }
    }
    
    func shouldLoadMoreStories(story apperedStory: Story) -> Bool {
        guard !currentlyLoading, !hasMoreStories else {
            return false
        }
        
        let comparedStoryIndex = stories.count - 3
        
        guard comparedStoryIndex > 0 else {
            return false
        }
        
        let comparedStory = self.stories[comparedStoryIndex]

        return comparedStory.id == apperedStory.id
    }
    
    func loadFeed(page: Int = 1, filtersApplying: Bool = false) {
        DispatchQueue.main.async {
            self.currentlyLoading = true
            self.currentlyFiltersApplying = filtersApplying
        }
        let request = Feed.Network.Request(page: page)
        self.interactor?.loadFeed(request: request)
    }
    
    func refreshFeed() {
        if !currentlyRefreshing {
            DispatchQueue.main.async {
                self.currentlyRefreshing = true
            }
            interactor?.refreshFeed(request: Feed.Network.Request(page: 1))
        }
    }
    
    func loadStoryImages(stories: [Story]) {
        interactor?.loadFeedImages(request: Feed.StoryImage.Request(stories: stories))
    }
    
    func displayFeed(viewModel: Feed.Network.ViewModel) {
        DispatchQueue.main.async {
            self.hasMoreStories = viewModel.hasMoreStories
            self.currentPage = viewModel.currentPage
            self.currentlyLoading = false
            if self.currentlyFiltersApplying {
                self.scrollToTop?()
                self.stories = viewModel.stories
                self.currentlyFiltersApplying = false
            } else {
                self.stories.append(contentsOf: viewModel.stories)
            }
            self.loadStoryImages(stories: viewModel.stories)
        }
    }
    
    func displayFeed(error: String) {
        DispatchQueue.main.async {
            self.error = error
            self.currentlyLoading = false
        }
    }
    
    func displayRefreshedFeed(viewModel: Feed.Network.ViewModel) {
        DispatchQueue.main.async {
            self.hasMoreStories = viewModel.hasMoreStories
            self.currentPage = viewModel.currentPage
            self.stories = viewModel.stories
            self.loadStoryImages(stories: viewModel.stories)
            self.currentlyRefreshing = false
            self.currentlyLoading = false
        }
    }
    
    func displayStoryImage(viewModel: Feed.StoryImage.ViewModel) {
        DispatchQueue.main.async {
            let storyIndex = self.stories.firstIndex { $0.id == viewModel.story.id }
            guard let index = storyIndex else {
                return
            }
            
            var story = self.stories[index]
            story.isImageLoading = false
            if viewModel.image != nil {
                story.image = viewModel.image
            }
            self.stories[index] = story
        }
    }
}