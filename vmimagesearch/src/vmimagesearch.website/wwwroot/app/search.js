var mod = angular.module('typeAheadModule', ['ui.bootstrap', 'ui.filters', 'angularMoment']);
mod.filter('addRandom', function () {
    return function (input, length) {
        var text = "";
        var possible = "abcdefghijklmnopqrstuvwxyz";

        for (var i = 0; i < length; i++)
            text += possible.charAt(Math.floor(Math.random() * possible.length));
        return input + text;
    }
});
mod.filter('splitter', function () {
    return function (input) {
        console.log(input);
        return input.split(';');
    }
});
mod.filter('removenonalphanumeric', function () {
    return function (input) {
        return input.replace(/\W+/g, "")
    }
});
mod.controller('TypeaheadCtrl', function ($scope, $http, $anchorScroll, $location) {
    $scope.showScriptPanel = false;
    $scope.Location = "";
    $scope.imageScript = {};
    $scope.assignResult = function (val) {
        $scope.imageScript = val;
        $scope.showScriptPanel = true;
        if ($location.hash() !== "scriptPanelAnchor") {
            $location.hash("scriptPanelAnchor");
        } else {
            $anchorScroll();
        }
        console.log($scope);
    };
    $scope.getSuggestions = function (val) {
        return $http.get('https://vmimagesearch.search.windows.net/indexes/imageindex/docs/suggest', {
            params: {
                "api-version": "2015-02-28",
                "search": val,
                "suggesterName": "autocomplete",
                "fuzzy": "true",
                "$top": "10",
                "api-key": "43679C1A36174339BE7BB14842B2AE92",
                "searchFields": "Label"
            }
        }).then(function (response) {
            return response.data.value;
        });
    };

    $scope.getSearch = function (val) {
        return $http.get('https://vmimagesearch.search.windows.net/indexes/imageindex/docs', {
            params: {
                "api-version": "2015-02-28",
                "search": val,
                "api-key": "43679C1A36174339BE7BB14842B2AE92"
            }
        }).then(function (response) {
            $scope.showScriptPanel = false;
            $scope.Results = response.data.value;
            $scope.Results.forEach(function (result) {
                result["LocArray"] = result.Location.split(";");
                result["Name"] = "";
                result["Password"] = "";
                result["CloudService"] = "";
                result["ExistingService"] = false;
                result["Location"] = result["LocArray"][0];
            });
        });
    };
    $scope.onSelect = function (item, model, label) {
        $scope.getSearch(label);
    };
});
