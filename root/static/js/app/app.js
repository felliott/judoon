/*jshint globalstrict: true */
/*global angular */

'use strict';

var judoonApp = angular.module(
    'judoon',
    ['ngRoute', 'ngSanitize', 'contenteditable', 'ui.bootstrap',
     'judoon.services', 'judoon.controllers', 'judoon.directives']
);

judoonApp.config(
    ['$locationProvider', '$routeProvider',
     function($locationProvider, $routeProvider) {

         $locationProvider.html5Mode(true);
         $routeProvider
             .when('/user/:userName', {
                 templateUrl    : '/static/html/partials/user.html',
                 controller     : 'UserCtrl',
                 reloadOnSearch : false,
                 resolve        : {
                     user: ['$route', 'User', function($route, User) {
                         var userName = $route.current.params.userName;
                         return User.get(userName);
                     }]
                 }
             })
             .when('/user/:userName/dataset/:datasetId', {
                 templateUrl    : '/static/html/partials/dataset.html',
                 controller     : 'DatasetCtrl',
                 reloadOnSearch : false,
                 resolve        : {
                     user: ['$route', 'User', function($route, User) {
                         var userName = $route.current.params.userName;
                         return User.get(userName);
                     }],
                     dataset: ['$route', 'Dataset', function($route, Dataset) {
                         var datasetId = $route.current.params.datasetId;
                         return Dataset.get(datasetId);
                     }]
                 }
             })
             .when('/user/:userName/page/:pageId', {
                 templateUrl: '/static/html/partials/page.html',
                 controller: 'PageCtrl',
                 resolve: {
                     user: ['$route', 'User', function($route, User) {
                         var userName = $route.current.params.userName;
                         return User.get(userName);
                     }],
                     page: ['$route', 'Pages', function($route, Pages) {
                         var pageId = $route.current.params.pageId;
                         return Pages.get(pageId);
                     }]
                 }
             })
             .otherwise({redirectTo: '/'});
     }
    ]
);
