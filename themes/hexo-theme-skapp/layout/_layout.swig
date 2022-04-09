<!DOCTYPE html>
<html lang="{{ config.language|default(theme.language) }}">
<head>
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-6942839821989447"
     crossorigin="anonymous"></script>
    <meta charset="utf-8" />
    {% block title %}
        <title>{% if page.title %}{{ page.title }} | {% endif %}{{ config.subtitle|default(theme.subtitle) }}</title>
    {% endblock %}
    <meta name="description" content="技术博客|分享各类技术信息|分享日常使用的工具技术">
    <meta name="google-site-verification" content="R3m7NgTKKhEvPx0ADHPDEdwUnfnjbuX8vbawkixPz_U" />
    {% include './_partial/common/head.swig' %}

    {% block pageCss %}
    {% endblock %}
</head>
<body ontouchstart>
    {% block loader %}
        {% include './_partial/common/loader.swig' %}
    {% endblock %}

    <div id="page" class="page js-hidden">
        {% block header %}
            {% include './_partial/common/header.swig' %}
        {% endblock %}

        {% block main %}
        {% endblock %}

        {% block footer %}
            {% include './_partial/common/footer.swig' %}
        {% endblock %}

        {% block backTop %}
            {% include './_partial/common/back-top.swig' %}
        {% endblock %}
    </div>

    <!-- build:js /js/common.js -->
        <script type="text/javascript" src="js/common/utils.js"></script>
        <script type="text/javascript" src="js/common/pack.js"></script>
        <script type="text/javascript" src="js/common/animation.js"></script>
        <script type="text/javascript" src="js/layout/loading.js"></script>
        <script type="text/javascript" src="js/layout/header.js"></script>
        <script type="text/javascript" src="js/layout/back-top.js"></script>
        <script type="text/javascript" src="js/layout/post.js"></script>
    <!-- endbuild -->

    {% block pagejs %}
    {% endblock %}

    {% block other %}
    {% endblock %}

    {% include './_partial/common/math.swig' %}
</body>
</html>
