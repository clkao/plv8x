sequelize:
	npm i ../sequelize
	ln -sf ../../{util,events} node_modules/sequelize/node_modules/ 
	onejs build  node_modules/sequelize/package.json sequelize.js
