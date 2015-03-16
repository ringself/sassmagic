##目录结构

		sassmagic/
		|
		|– base/
		|   |– _reset.scss       # Reset/normalize
		|   |– _typography.scss  # Typography rules
		|   ...                  # Etc…
		|
		|– components/
		|   |– _buttons.scss     # Buttons
		|   |– _carousel.scss    # Carousel
		|   |– _cover.scss       # Cover
		|   |– _dropdown.scss    # Dropdown
		|   ...                  # Etc…
		|
		|– partials/
		|   |– _navigation.scss  # Navigation
		|   |– _grid.scss        # Grid system
		|   |– _header.scss      # Header
		|   |– _footer.scss      # Footer
		|   |– _sidebar.scss     # Sidebar
		|   |– _forms.scss       # Forms
		|   ...                  # Etc…
		|
		|– pages/
		|   |– _home.scss        # Home specific styles
		|   |– _contact.scss     # Contact specific styles
		|   ...                  # Etc…
		|
		|– themes/
		|   |– _theme.scss       # Default theme
		|   |– _admin.scss       # Admin theme
		|   ...                  # Etc…
		|
		|– helpers/
		|   |– _variables.scss   # Sass Variables
		|   |– _functions.scss   # Sass Functions
		|   |– _mixins.scss      # Sass Mixins
		|   |– _helpers.scss     # Class & placeholders helpers
		|
		|– vendors/
		|   |– _bootstrap.scss   # Bootstrap
		|   |– _jquery-ui.scss   # jQuery UI
		|   ...                  # Etc…
		|
		|
		`– main.scss             # primary Sass file

###目录结构描述

目录结构采用的是常见的7-1模式的结构：7个文件夹，1个文件。基本上，你需要将所有的部件放进7个不同的文件夹和一个位于根目录的文件（通常命名为 main.scss）中——这个文件编译时会引用所有文件夹而形成一个CSS样式表。

####base

`base/`文件夹存放项目中的模板文件。在这里，可以找到重置文件、排版规范文件或者一个样式表（我通常命名为`_base.scss`）——定义一些HTML元素公认的标准样式。

####components

对于小型组件来说，有一个`components/`文件夹来存放。相对于`partials/`的宏观（定义全局线框结构），`components/`更专注于局部组件。该文件夹包含各类具体模块，基本上是所有的独立模块，比如一个滑块、一个加载块、一个部件……由于整个网站或应用程序主要由微型模块构成，`components/`中往往有大量文件。

####partials

`partials/`文件夹存放构建网站或者应用程序使用到的布局部分。该文件夹存放网站主体（头部、尾部、导航栏、侧边栏...）的样式表、栅格系统甚至是所有表单的CSS样式。(备注：常常也命名为`layout/`)。

####pages

如果页面有特定的样式，最好将该样式文件放进`pages/`文件夹并用页面名字。例如，主页通常具有独特的样式，因此可以在`pages/`下包含一个`_home.scss`以实现需求。

####themes

在大型网站和应用程序中，往往有多种主题。虽有多种方式管理这些主题，但是我个人更喜欢把它们存放在`themes/`文件夹中。

####helpers

`helpers/`文件夹包含了整个项目中使用到的Sass辅助工具，这里存放着每一个全局变量、函数、混合宏和占位符。(备注，常常也命名为`utils/`)

该文件夹的经验法则是，编译后这里不应该输出任何CSS，单纯的只是一些Sass辅助工具。

####vendors

最后但并非最终的，大多数的项目都有一个`vendors/`文件夹，用来存放所有外部库和框架（Normalize, Bootstrap, jQueryUI, FancyCarouselSliderjQueryPowered……）的CSS文件。将这些文件放在同一个文件中是一个很好的说明方式:"嘿，这些不是我的代码，无关我的责任。"

如果你重写了任何库或框架的部分，建议设置第8个文件夹`vendors-extensions/`来存放，并使用相同的名字命名。例如，`vendors-extensions/_boostrap.scss`文件存放所有重写Bootstrap默认CSS之后的CSS规则。这是为了避免在原库或者框架文件中进行二次编辑。

####main.scss

主文件（通常写作`main.scss`，也常常命名为`style.scss`）应该是整个代码库中唯一开头不用下划线命名的Sass文件。除 `@import`和注释外，该文件不应该包含任何其他代码。


#####main.scss文件引入顺序

文件应该按照存在的位置顺序依次被引用进来：

1. vendors/
2. helpers/
3. base/
4. partials/
5. components/
6. pages/
7. themes/

为了保持可读性，主文件应遵守如下准则：

- 每个 `@import`引用一个文件；
- 每个 `@import`单独一行；
- 从相同文件夹中引入的文件之间不用空行；
- 从不同文件夹中引入的文件之间用空行分隔；
- 忽略文件扩展名和下划线前缀。

例如：

		@import 'vendors/bootstrap';
		@import 'vendors/jquery-ui';

		@import 'helpers/variables';
		@import 'helpers/functions';
		@import 'helpers/mixins';
		@import 'helpers/placeholders';

		@import 'base/reset';
		@import 'base/typography';

		@import 'partials/navigation';
		@import 'partials/grid';
		@import 'partials/header';
		@import 'partials/footer';
		@import 'partials/sidebar';
		@import 'partials/forms';

		@import 'components/buttons';
		@import 'components/carousel';
		@import 'components/cover';
		@import 'components/dropdown';

		@import 'pages/home';
		@import 'pages/contact';

		@import 'themes/theme';
		@import 'themes/admin';

这里还有另一种引入的有效方式。令人高兴的是，它使文件更具有可读性；令人沮丧的是，更新时会有些麻烦。不管怎么说，由你决定哪一个最好，这没有任何问题。 对于这种方式，主要文件应遵守如下准则：

- 每个文件夹只使用一个`@import`
- 每个`@import`之后都断行
- 每个文件占一行
- 新的文件跟在最后的文件夹后面
- 文件扩展名都可以省略

例如：

		@import
		  'vendors/bootstrap',
		  'vendors/jquery-ui';

		@import
		  'helpers/variables',
		  'helpers/functions',
		  'helpers/mixins',
		  'helpers/placeholders';

		@import
		  'base/reset',
		  'base/typography';

		@import
		  'partials/navigation',
		  'partials/grid',
		  'partials/header',
		  'partials/footer',
		  'partials/sidebar',
		  'partials/forms';

		@import
		  'components/buttons',
		  'components/carousel',
		  'components/cover',
		  'components/dropdown';

		@import
		  'pages/home',
		  'pages/contact';

		@import
		  'themes/theme',
		  'themes/admin';

小技巧，为了避免人工一个一个文件引入，可以使用Ruby Sass扩展程序[sass-globbing](https://github.com/chriseppstein/sass-globbing)。