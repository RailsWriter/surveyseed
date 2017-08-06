angular.module('navigation', ['ngRoute', 'auth']).controller(
		'navigation',

		function($scope, $route, auth) {
			  $scope.currentPage = 1;
			  $scope.pageSize = 10;

			$scope.credentials = {};

			$scope.tab = function(route) {
				return $route.current && route === $route.current.controller;
			};

			$scope.authenticated = function() {
				return auth.authenticated;
			}

			$scope.login = function() {
				auth.authenticate($scope.credentials, function(authenticated) {
					if (authenticated) {
						console.log("Login succeeded")
						$scope.error = false;
					} else {
						console.log("Login failed")
						$scope.error = true;
					}
				})
			};

			$scope.logout = auth.clear;

		});

angular.module('navigation')
		.controller('acceptTerms',
			function($scope, $route) {
				$scope.acceptTermsTxt='https://www.ketsci.com/users/PrivacyPolicy'

				$scope.acceptTerms = function(){

				}
			}
);
