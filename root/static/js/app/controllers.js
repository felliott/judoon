'use strict';

/* Controllers */

function PageCtrl($scope, $routeParams, Page) {

    $scope.editmode = 0;

    $scope.pageId = $routeParams.pageId;
    $scope.pageLoaded = 0;
    $scope.page = Page.get({id: $scope.pageId}, function (page) {
        $scope.pageLoaded = 1;
    });

    $scope.pageDirty = 0;
    $scope.$watch('page', function () {
        if ($scope.pageLoaded) {
            $scope.pageDirty = 1;
        }
    }, true);

    $scope.updatePage = function(){
        Page.update({
            id:         $scope.pageId,
            title:      $scope.page.title,
            preamble:   $scope.page.preamble,
            postamble:  $scope.page.postamble,
            dataset_id: $scope.page.dataset_id,
        });
    };

    $scope._addColumn = function(columnTitle) {
        var newColumn = {title: columnTitle, template: ''};
        $scope.page.columns.push(newColumn);
        return newColumn;
    };

    $scope._rmColumn = function(deleteColumn) {
        for (var idx in $scope.page.columns) {
            if ($scope.page.columns[idx] === deleteColumn) {
                $scope.page.columns.splice(idx, 1);
            }
        }
    };

    $scope.getServerData = function ( sSource, aoData, fnCallback ) {
        $.ajax( {
            "dataType": "json",
            "type": "GET",
            "url": sSource,
            "data": aoData,
            "success": [
                function(data) {
                    var templates = [];
                    for (var idx in $scope.page.columns) {
                        templates.push(
                            Handlebars.compile(
                                $scope.page.columns[idx].template
                            )
                        );
                    }

                    var new_data = [];
                    for (var i = 0; i < data.tmplData.length; i++) {
                        new_data[i] = [];
                        for (var j = 0; j < templates.length; j++) {
                            new_data[i][j] = templates[j](data.tmplData[i]);
                        }
                    }
                    data.aaData = new_data;
                },
                fnCallback
            ],
        } );
    };
}


function ColumnCtrl($scope) {

    $scope.currentColumn;
    $scope.newColumnName;
    $scope.deleteColumn;

    $scope.addColumn = function () {
        $scope.currentColumn = $scope.$parent._addColumn($scope.newColumnName);
    }


    $scope.removeColumn = function() {
        if (!$scope.deleteColumn) {
            return false;
        }

        var deleteColumn = confirm("Are you sure you want to delete this column?");
        if (deleteColumn) {
            if ($scope.currentColumn === $scope.deleteColumn) {
                $scope.currentColumn = null;
            }

            $scope.$parent._rmColumn($scope.deleteColumn);
        }
    }
}

