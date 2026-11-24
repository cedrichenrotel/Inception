DOCKER_COMP = docker compose -f srcs/docker-compose.yml
DOWN = $(DOCKER_COMP) down

all:
	mkdir -p ~/data/mariadb ~/data/wordpress
	$(DOCKER_COMP) up -d --build

down:
	$(DOWN)

clean:
	$(DOWN) --rmi all

fclean:
	$(DOWN) --rmi all -v
	sudo rm -rf ~/data

re: fclean all

.PHONY: all down clean fclean re