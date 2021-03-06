# -*- coding: utf-8 -*-
# Author: Vladislav Fursov (ghostrussian@gmail.com)
require 'digest'

class RegTmp
  attr_accessor :qn, :answers

  def initialize
    @qn = 0
    @answers = []
  end
end

class Registration
  attr_accessor :type, :tmpReg, :game

  QUESTIONS_WITH_LOGIN_PASSWORD = [
      'Логин',
      'Пароль'
  ]

  QUESTIONS = [
      'Кто? (прим. Вася)',
      'Кого? (Васю)',
      'Кому? (Васе)',
      'Кем? (Васей)',
      'О ком? (Васе)',
      'Чей? (Васи)',
      'Ваш пол? (М или Ж)',
      'Все верно? (Да/Нет)'
  ]

  LOGIN_REGEX = /^[[A-Za-z0-9]|_|-]{3,30}$/i

  USER_EXIST = 'Пользователь с таким логином уже существует, выберите другой'
  NAME_EXIST = 'Пользователь с таким именем уже существует, выберите другое имя'
  REGISTRED_MESSAGE = 'Спасибо за регистрацию.'
  REGISTRATION_ABORTED = 'Регистрация отменена.'
  CHARACTERS_ARE_NOT_ALLOWED_MESSAGE = 'Пожалуйста, задайте нормальное имя.'
  CHARACTERS_LOGIN_NOT_ALLOWED_MESSAGE = 'В логине допустимы только символы латинского алфавита, цифры и знаки "-" и "_"'

  def initialize(type, game, user_name_regex=USER_NAME_REGEX)
    @game = game
    @type = type
    @tmpReg = {}
    @user_name_regex = user_name_regex
  end

  def self.GetLoginOfType(id, type)
    return "#{id}@#{type}"
  end

  def RegPlayer(id, answer, password = '')
    login = GetLogin(id)

    @tmpReg[login] = RegTmp.new unless @tmpReg.key?(login)
    n = @tmpReg[login].qn

    if n < 7 && !@game.MyNameUnique?(login, answer, true)
      return NAME_EXIST + "\n" + QUESTIONS[n-1]
    end

    if n == 7 # sex
      case answer
        when /^[М]$/i
          answer = 'male'
        when /^[Ж]$/i
          answer = 'female'
        else
          answer = ''
      end
    end

    if n == 8 # confirm
      case answer
        when /^((д)|(да))$/i
          unless @game.check(login)
            @game.players[login].addr = login
            @game.players[login].pwd = Digest::MD5.hexdigest(password) unless password.empty?
            @game.CharCreate(login, @tmpReg[login].answers.drop(1)) # fixme: first element is nil
          end

          return REGISTRED_MESSAGE
        when /^((н)|(нет))$/i
          Reset(id)
          return REGISTRATION_ABORTED
        else
          answer = ''
      end
    end

    # check allowed name
    if !(answer =~ /^#{@user_name_regex}$/i) && n > 0 && !answer.empty?
      return CHARACTERS_ARE_NOT_ALLOWED_MESSAGE + "\n" + QUESTIONS[n-1]
    end


    @tmpReg[login].answers[n] = answer if n > 0 && !answer.empty?

    if n >= QUESTIONS.length && !answer.empty?
    end

    n -= 1 if n > 0 && answer.empty?

    ask = QUESTIONS[n]

    @tmpReg[login].qn = n + 1
    return ask
  end

  def GetLogin(id)
    return Registration.GetLoginOfType(id, @type)
  end

  def RegPlayerWithLoginAndPassword(tmpId, answer)
    tempLogin = GetLogin(tmpId)

    @tmpReg[tempLogin] = RegTmp.new unless @tmpReg.key?(tempLogin)
    n = @tmpReg[tempLogin].qn

    ask = nil

    if @game.players.key?(GetLogin(answer)) && n == 1
      return USER_EXIST
    end

    if @game.players.key?(GetLogin(answer)) && n == 1
      return USER_EXIST
    end

    @tmpReg[tempLogin].answers[n-1] = answer if n > 0 && n <= QUESTIONS_WITH_LOGIN_PASSWORD.length

    if !(answer =~ LOGIN_REGEX) && n == 1
      return CHARACTERS_LOGIN_NOT_ALLOWED_MESSAGE + "\n" + QUESTIONS_WITH_LOGIN_PASSWORD[n-1]
    end

    if n >= QUESTIONS_WITH_LOGIN_PASSWORD.length
      id = @tmpReg[tempLogin].answers[0]
      pass = @tmpReg[tempLogin].answers[1]

      if pass.empty?
        return QUESTIONS_WITH_LOGIN_PASSWORD[1]
      end

      answer = '' if n == QUESTIONS_WITH_LOGIN_PASSWORD.length
      ask = RegPlayer(id, answer, pass)
    else
      n -= 1 if n > 0 && answer.empty?
      ask = QUESTIONS_WITH_LOGIN_PASSWORD[n]
    end

    @tmpReg[tempLogin].qn = n + 1
    return ask
  end

  def Reset(id)
    login = GetLogin(id)
    login2 = @tmpReg[login].answers[0] if @tmpReg.key?(login)
    @tmpReg.delete(GetLogin(login2))
    @tmpReg.delete(login)
  end

  # getters
  def questions_with_login_password_messages
    return QUESTIONS_WITH_LOGIN_PASSWORD
  end

  def questions_messages
    return QUESTIONS
  end

  def user_exist_message
    return USER_EXIST
  end

  def registred_message
    return REGISTRED_MESSAGE
  end

  def registration_aborted_message
    return REGISTRATION_ABORTED
  end

  def characters_are_not_allowed_message
    return CHARACTERS_ARE_NOT_ALLOWED_MESSAGE
    end

  def characters_login_not_allowed_message
    return CHARACTERS_LOGIN_NOT_ALLOWED_MESSAGE
  end
end