(function(angular) {
  'use strict';
  var app = angular.module('ketscipanel', ["ngRoute","auth","home","navigation",
		"xeditable","angularUtils.directives.dirPagination"])
    app.run(function(editableOptions) {
	  editableOptions.theme = 'bs3'; // bootstrap3 theme. Can be also 'bs2', 'default'
	});

  app.config(function($routeProvider, $httpProvider, $locationProvider) {
		console.log("setting up config::controllers");

		$locationProvider.html5Mode(true);

		$routeProvider.when('/', {
			templateUrl : 'js/home/home.html',
			controller : 'home'
		}).when('/home', {
			templateUrl : 'js/home/home.html',
			controller : 'home'
		}).when('/login', {
			templateUrl : 'js/navigation/login.html',
			controller : 'navigation'
		}).otherwise('/');

		$httpProvider.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';

	}).run(function(auth) {

		// Initialize auth module with the home page and login/logout path
		// respectively
		auth.init('/home', '/login', '/logout');
	});
 
  app.controller('appController',['$scope',function($scope){
		$scope.$on('LOAD',function(){$scope.loading=true});
		$scope.$on('UNLOAD',function(){$scope.loading=false});
	}]);
})(window.angular);