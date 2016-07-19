angular.module('analyticsintegration', [
  'ngRoute'
  'analyticsintegration.progress'
])
.config ($routeProvider) ->
  'use strict'
  $routeProvider
    .when '/progress',
      controller: 'ProgressCtrl'
      templateUrl: '/analyticsintegration/progress/progress.html'
    .otherwise
      redirectTo: '/progress'

