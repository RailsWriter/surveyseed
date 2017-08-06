angular.module('auth', []).factory(
		'auth',

		function($rootScope, $http, $location) {

			enter = function() {
				if ($location.path() != auth.loginPath) {
					auth.path = $location.path();
					if (!auth.authenticated) {
						$location.path(auth.loginPath);
					}
				}					
			}

			var auth = {

				authenticated : false,

				loginPath : '/login',
				logoutPath : '/logout',
				homePath : '/home',
				acceptTerms:'/acceptTerms',
				path : $location.path(),

				authenticate : function(credentials, callback) {
					console.log("credentials="+credentials.username+","+credentials.password);
					var headers = credentials && credentials.username ? {
						authorization : "Basic "
								+ btoa(credentials.username + ":"
										+ credentials.password)
					} : {};
					
					console.log("headers = "+headers);
					var credData = {}
					credData.credentials={
						emailId:credentials.username,
						password:credentials.password
					}
					console.log("credData"+JSON.stringify(credData,null,"  "))
					$http.post('https://ketsci.com/users/login', credData).success(function(data) {
						console.log('login success = '+JSON.stringify(data,null,"  "));
						console.log('$location.path()::'+$location.path())
						if (data.emailId) {
							auth.authenticated = true;
						} else {
							auth.authenticated = false;
						}
						callback && callback(auth.authenticated);

						console.log("auth.authenticated:"+auth.authenticated)
						console.log("data.acceptedTerms:"+data.acceptedTerms)

						if(auth.authenticated && data.acceptedTerms=='f')
							$location.path(auth.path==auth.loginPath ? auth.acceptTerms : auth.path);
						else
							$location.path(auth.path==auth.loginPath ? auth.homePath : auth.path);
					}).error(function() {
						console.log('login failure');
						auth.authenticated = false; 
						callback && callback(false);
					});
/*
					auth.authenticated = true;
					callback && callback(auth.authenticated);
					$location.path(auth.path==auth.loginPath ? auth.homePath : auth.path);
*/
				},

				clear : function() {
					console.log("logout called");
					$location.path(auth.loginPath);
					auth.authenticated = false;
					$http.post('\logout').success(function() {
						console.log("Logout succeeded");
					}).error(function(data) {
						console.log("Logout failed");
					});
				},

				init : function(homePath, loginPath, logoutPath) {
					console.log("auth init called");
					auth.homePath = homePath;
					auth.loginPath = loginPath;
					auth.logoutPath = logoutPath;

					auth.authenticate({}, function(authenticated) {
						if (authenticated) {
							console.log("user already authenticated in init");
							$location.path(auth.path);
						}
					})

					// Guard route changes and switch to login page if unauthenticated
					$rootScope.$on('$routeChangeStart', function() {
						enter();
					});

				}

			};

			return auth;

		});