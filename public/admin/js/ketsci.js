(function(angular) {
  'use strict';
  var app = angular.module('ketSciAdmin', ["ngRoute","auth","home","navigation",
		"datamanager","xeditable"])
    app.run(function(editableOptions) {
	  editableOptions.theme = 'bs3'; // bootstrap3 theme. Can be also 'bs2', 'default'
	});

//  app.run(function($rootScope, $templateCache) {
//	    $rootScope.$on('$routeChangeStart', function(event, next, current) {
//	        if (typeof(current) !== 'undefined'){
//	            $templateCache.remove(current.templateUrl);
//	        }
//	    });
//	});

  app.config(function($routeProvider, $httpProvider, $locationProvider) {
		console.log("setting up config::controllers");

		$locationProvider.html5Mode(true);

		$routeProvider.when('/', {
			templateUrl : 'js/home/home.html',
			controller : 'home'
		}).when('/login', {
			templateUrl : 'js/navigation/login.html',
			controller : 'navigation'
		}).when('/acceptTerms', {
			templateUrl : 'js/navigation/acceptTerms.html',
			controller : 'acceptTerms'
		}).when('/home', {
			templateUrl : 'js/home/home.html',
			controller : 'home'
		}).otherwise('/');

		$httpProvider.defaults.headers.common['X-Requested-With'] = 'XMLHttpRequest';

	}).run(function(auth) {

		// Initialize auth module with the home page and login/logout path
		// respectively
		auth.init('/home', '/login', '/logout', 'metrics');
	});
 
  app.controller('appController',['$scope',function($scope){
		$scope.$on('LOAD',function(){$scope.loading=true});
		$scope.$on('UNLOAD',function(){$scope.loading=false});
	}]);
})(window.angular);