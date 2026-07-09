<?php

namespace app\controllers;

use yii\web\Controller;
use yii\web\Response;

class SiteController extends Controller
{
    public function actionIndex(): Response
    {
        \Yii::$app->response->format = Response::FORMAT_JSON;
        return $this->asJson(['message' => 'Welcome to the API']);
    }

    public function actionHealth(): Response
    {
        \Yii::$app->response->format = Response::FORMAT_JSON;
        return $this->asJson(['status' => 'ok']);
    }

    public function actionError(): Response
    {
        \Yii::$app->response->format = Response::FORMAT_JSON;
        $exception = \Yii::$app->errorHandler->exception;
        return $this->asJson(['error' => $exception ? $exception->getMessage() : 'Not Found']);
    }
}
