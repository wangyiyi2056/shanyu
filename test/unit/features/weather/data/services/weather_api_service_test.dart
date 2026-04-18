import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiking_assistant/features/weather/data/models/weather_model.dart';

void main() {
  group('WeatherData', () {
    test('iconData returns correct icon for sunny', () {
      final weather = WeatherData(
        temperature: 25,
        windSpeed: 10,
        weatherCode: 0,
        description: '晴朗',
        updatedAt: DateTime.now(),
      );
      expect(weather.iconData, Icons.wb_sunny);
    });

    test('iconData returns correct icon for rain', () {
      final weather = WeatherData(
        temperature: 20,
        windSpeed: 15,
        weatherCode: 61,
        description: '小雨',
        updatedAt: DateTime.now(),
      );
      expect(weather.iconData, Icons.water_drop);
    });

    test('iconData returns correct icon for thunderstorm', () {
      final weather = WeatherData(
        temperature: 18,
        windSpeed: 20,
        weatherCode: 95,
        description: '雷雨',
        updatedAt: DateTime.now(),
      );
      expect(weather.iconData, Icons.bolt);
    });

    test('isGoodForHiking returns true for good weather', () {
      final weather = WeatherData(
        temperature: 22,
        windSpeed: 10,
        weatherCode: 1,
        description: '主要晴朗',
        updatedAt: DateTime.now(),
      );
      expect(weather.isGoodForHiking, true);
    });

    test('isGoodForHiking returns false for rain', () {
      final weather = WeatherData(
        temperature: 20,
        windSpeed: 10,
        weatherCode: 63,
        description: '中雨',
        updatedAt: DateTime.now(),
      );
      expect(weather.isGoodForHiking, false);
    });

    test('isGoodForHiking returns false for strong wind', () {
      final weather = WeatherData(
        temperature: 20,
        windSpeed: 35,
        weatherCode: 1,
        description: '主要晴朗',
        updatedAt: DateTime.now(),
      );
      expect(weather.isGoodForHiking, false);
    });

    test('hikingAdvice recommends caution for high temperature', () {
      final weather = WeatherData(
        temperature: 32,
        windSpeed: 10,
        weatherCode: 0,
        description: '晴朗',
        updatedAt: DateTime.now(),
      );
      expect(weather.hikingAdvice.contains('气温较高'), true);
    });

    test('hikingAdvice recommends caution for low temperature', () {
      final weather = WeatherData(
        temperature: 2,
        windSpeed: 10,
        weatherCode: 1,
        description: '主要晴朗',
        updatedAt: DateTime.now(),
      );
      expect(weather.hikingAdvice.contains('气温较低'), true);
    });

    test('weatherCodeToDescription handles unknown codes', () {
      expect(weatherCodeToDescription(999), '未知');
    });
  });
}
