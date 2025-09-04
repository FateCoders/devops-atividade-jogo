# Terra de Libertos

## Sobre o Jogo
Em um Brasil colonial, um quilombo se inicia em meio a uma floresta na Capitania de Pernambuco. O líder quilombola Zumbi dos Palmares ao lado de sua esposa guerreira Dandara lidam com as tensões com os senhores de engenho: envio de bandeirantes para resgate de fugitivos escravizados e ameaças aos quilombolas. O líder deve tomar decisões para garantir a paz no quilombo.

## Tecnologias Utilizadas
### Gerenciamento
- GitHub Project.

### Desenvolvimento
- Godot;
- GitHub Actions;
- Git;
- Docker;
- SonarQube.

### Arte Visual
- Aseprite.

### Audio
- FL Studio.

## Padrões e Boas Práticas
### Commits
- `:sparkles:` :sparkles: -> features;
- `:bug:` :bug: -> correções;
- `:recycle:` :recycle: -> refatorações;
- `:art:` :art: -> estilização;
- `:fire:` :fire: -> exclusões;
- `:book:` :book: -> adição de arquivos.

#### Exemplo de uso:
- ✨ adicionando mecanica de dano;
- 🐛 arrumando erro de colisao do mapa;
- 🎨 adicionando UI.
- ♻️ refatorando o script do jogador para separar a lógica de movimento.
- 🔥 excluindo assets de prototipagem não utilizados.
- 📖 adicionando documentação sobre o sistema de inventário.


## Estrutura de Diretórios
A organização das pastas do projeto segue o padrão abaixo para facilitar a manutenção e localização de arquivos.

- **📁 Assets/**
  - **Função:** Armazena todos os recursos visuais e sonoros do jogo.
  - **Subpastas:**
	- `Sprites/`: Imagens de personagens, inimigos, objetos, itens, etc.
	- `Audio/`: Efeitos sonoros (.wav, .ogg) e trilhas musicais.
	- `Fonts/`: Fontes personalizadas usadas em HUDs e menus.
	- `Tilesets/`: Conjuntos de tiles utilizados na criação dos mapas.

- **📁 Scenes/**
  - **Função:** Guarda todas as cenas do jogo. Cada cena é um elemento jogável, tela ou parte reutilizável.
  - **Subpastas:**
	- `Main/`: Cena principal do jogo, que controla o fluxo entre menus, fases, HUD etc.
	- `UI/`: Telas como Menu Principal, HUD, Pause, Game Over.
	- `Levels/`: Cenas dos níveis/fases jogáveis.
	- `Characters/`: Cena do jogador, inimigos, NPCs, etc.
	- `Misc/`: Cenas auxiliares, como animações de transição ou efeitos.

- **📁 Scripts/**
  - **Função:** Guarda os scripts GDScript (`.gd`) organizados por tipo.
  - **Subpastas:**
	- `Characters/`: Scripts de comportamento do jogador, inimigos, NPCs.
	- `UI/`: Scripts de botões, menus, HUD.
	- `Levels/`: Scripts de lógica de fases, carregamento de cenas, etc.

- **📁 Autoload/**
  - **Função:** Contém scripts globais que ficam disponíveis em todo o jogo.
  - **Exemplo:**
	- `Globals.gd`: Guarda pontuação, nome do jogador, fase atual, dados de save etc.
	- *Esse script deve ser registrado em Project → Project Settings → Autoload.*

- **📁 Resources/**
  - **Função:** Armazena arquivos de configuração, dados e temas reutilizáveis.
  - **Subpastas:**
	- `Themes/`: Arquivos `.tres` de temas visuais para menus, HUDs, etc.
	- `Data/`: Arquivos JSON, CSV ou customizados com dados de inimigos, itens, textos, etc.

## Integrantes
  <table>
	<tr>
	  <td align="center">
		<a href="https://github.com/mygk-bea" title="Acessar perfil de Beatriz">
		  <img src="https://avatars.githubusercontent.com/u/100007869?v=4" width="100px;" alt="Foto de Beatriz Meyagusko no GitHub"/><br>
		  <sub>
			<b>Beatriz</b>
		  </sub>
		</a>
	  </td>
	  <td align="center">
		<a href="https://github.com/nogueirafnd7" title="Acessar perfil de Bruno">
		  <img src="https://avatars.githubusercontent.com/u/155416552?v=4" width="100px;" alt="Foto do Bruno Nogueira no GitHub"/><br>
		  <sub>
			<b>Bruno</b>
		  </sub>
		</a>
	  </td>
	  <td align="center">
		<a href="https://github.com/Kits93" title="Acessar perfil de João">
		  <img src="https://avatars.githubusercontent.com/u/126159386?v=4" width="100px;" alt="Foto de João Victor no GitHub"/><br>
		  <sub>
			<b>João</b>
		  </sub>
		</a>
	  </td>
	  <td align="center">
		<a href="https://github.com/liabueno" title="Acessar perfil de Júlia">
		  <img src="https://avatars.githubusercontent.com/u/117865464?v=4" width="100px;" alt="Foto de Júlia Bueno no GitHub"/><br>
		  <sub>
			<b>Júlia</b>
		  </sub>
		</a>
	  </td>
	  <td align="center">
		<a href="https://github.com/luizfiuzaa" title="Acessar perfil de Luiz">
		  <img src="https://avatars.githubusercontent.com/u/96220499?v=4" width="100px;" alt="Foto de Luiz Fiuza no GitHub"/><br>
		  <sub>
			<b>Luiz</b>
		  </sub>
		</a>
	  </td>
	  <td align="center">
		<a href="https://github.com/MarlonVBP" title="Acessar perfil de Marlon">
		  <img src="https://avatars.githubusercontent.com/u/101027484?v=4" width="100px;" alt="Foto de Marlon Passos no GitHub"/><br>
		  <sub>
			<b>Marlon</b>
		  </sub>
		</a>
	  </td>
	  <td align="center">
		<a href="https://github.com/sousa-p" title="Acessar perfil de Pedro">
		  <img src="https://avatars.githubusercontent.com/u/97417230?v=4" width="100px;" alt="Foto de Pedro Menck no GitHub"/><br>
		  <sub>
			<b>Pedro</b>
		  </sub>
		</a>
	  </td>
	  <td align="center">
		<a href="https://github.com/RaphaelSantos01" title="Acessar perfil de Raphael">
		  <img src="https://avatars.githubusercontent.com/u/125563006?v=4" width="100px;" alt="Foto de Raphael Santos no GitHub"/><br>
		  <sub>
			<b>Raphael</b>
		  </sub>
		</a>
	  </td>
	  <td align="center">
		<a href="https://github.com/thayM" title="Acessar perfil de Thayná">
		  <img src="https://avatars.githubusercontent.com/u/116041441?v=4" width="100px;" alt="Foto de Thayná Marostica no GitHub"/><br>
		  <sub>
			<b>Thayná</b>
		  </sub>
		</a>
	  </td>
	  <td align="center">
		<a href="https://github.com/vhfantes-Dev" title="Acessar perfil de Vitor">
		  <img src="https://avatars.githubusercontent.com/u/167342932?v=4" width="100px;" alt="Foto de Vitor Fantes no GitHub"/><br>
		  <sub>
			<b>Vitor</b>
		  </sub>
		</a>
	  </td>
	</tr>
</table>
